#!/bin/bash

# Arrays to hold directories
project_name="container-arch"
vpc_dir="$HOME/git/$project_name--aws-vpc"
cluster_dir="$HOME/git/$project_name--aws-ecs-cluster"
app_dir="$HOME/git/$project_name--aws-ecs-app"

AWS_ENV="dev"
REGISTRY_NAME="$AWS_ENV--chip"
REGISTRY_EXISTS=$(aws ecr describe-repositories --repository-names $REGISTRY_NAME 2>&1)

export AWS_REGION="us-east-2"

# Function to apply terraform infrastructure in a directory
apply_terraform() {
  local dir=$1

  if [[ "$dir" == "$app_dir" ]]; then
    # Check if ECR repository exists

    if [[ $REGISTRY_EXISTS == *"RepositoryNotFoundException"* ]]; then
      aws ecr create-repository --repository-name $REGISTRY_NAME --output text > /dev/null  

      if [ $? -ne 0 ]; then
        echo "ECR create failed"
        exit 1
      fi
    fi

    # Push "fidelissauro/chip:v2" image to the ECR
    CONTAINER_IMAGE="150100906110.dkr.ecr."$AWS_REGION".amazonaws.com/"$REGISTRY_NAME":latest"
    aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin 150100906110.dkr.ecr."$AWS_REGION".amazonaws.com
    docker pull fidelissauro/chip:v2
    docker tag fidelissauro/chip:v2 $CONTAINER_IMAGE
    docker push $CONTAINER_IMAGE
    pushd "$dir/terraform"

  else
    pushd "$dir"
  fi

  terraform workspace select "$AWS_ENV"
  terraform apply --auto-approve
  popd
}

# Function to destroy terraform infrastructure in a directory
destroy_terraform() {
  local dir=$1

  pushd "$dir"
  if [[ "$dir" == "$app_dir" ]]; then
    if [[ $REGISTRY_EXISTS != *"RepositoryNotFoundException"* ]]; then
      aws ecr delete-repository --repository-name "$REGISTRY_NAME" --force --output text > /dev/null

      if [ $? -ne 0 ]; then
        echo "ECR delete failed"
        exit 1
      fi
    fi
  fi
  
  terraform workspace select "$AWS_ENV"
  terraform destroy --auto-approve
  popd
}

case $1 in
  --apply|-A)
    # Ensure that user wants to apply infrastructure
    read -p "Are you sure you want to apply all infrastructure? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Exiting..."
      exit 0
    fi

    # Apply vpc directory first
    apply_terraform $vpc_dir

    # Apply cluster directories next
    apply_terraform $cluster_dir

    # Apply other directories last
    apply_terraform $app_dirs

    exit 0
    ;;
  --destroy|-D)
    # Ensure that user wants to destroy infrastructure
    read -p "Are you sure you want to destroy all infrastructure? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "Exiting..."
      exit 0
    fi

    # Destroy other directories first
    destroy_terraform $vpc_dir

    # Destroy cluster directories next
    destroy_terraform $cluster_dir

    # Destroy vpc directories last
    destroy_terraform $app_dirs

    exit 0
    ;;
  --test|-T)
    DNS_NAME=$(aws elbv2 describe-load-balancers \
      --names "$AWS_ENV--$project_name--lb" \
      --query 'LoadBalancers[0].DNSName' \
      --output text \
      --region $AWS_REGION \
      --no-cli-pager)

    case $2 in
      system)
        curl $DNS_NAME/system -H "Host: chip.linuxtips.demo" -i
        exit 0
        ;;
      cpu)
        while true; do
          curl $DNS_NAME/burn/cpu -H "Host: chip.linuxtips.demo" -i
        done
        ;;
      k6)
        pushd "$app_dir/load_test"
        k6 run -e LB_DNS=$DNS_NAME index.js
      ;;
    esac
    ;;
  *)
    echo "Usage: $0 [apply|destroy]"
    exit 1
    ;;
esac
