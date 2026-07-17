#!/bin/bash

# Arrays to hold directories
project_name="container-arch"
vpc_dir="$HOME/git/$project_name--aws-vpc"
cluster_dir="$HOME/git/$project_name--aws-ecs-cluster"
app_dir="$HOME/git/$project_name--aws-ecs-app"

AWS_ENV="dev"
REGISTRY_NAME="$AWS_ENV--chip"
SOURCE_IMAGE="fidelissauro/chip:v2"

export AWS_REGION="us-east-2"
export AWS_PAGER=""

# Push the app image to the ECR repository managed by terraform
push_image() {
  local account_id
  account_id=$(aws sts get-caller-identity --query 'Account' --output text)

  local registry="$account_id.dkr.ecr.$AWS_REGION.amazonaws.com"
  local container_image="$registry/$REGISTRY_NAME:latest"

  # The ECR repository is managed by terraform, but the image must exist
  # before the ECS service starts. Create just the repository first.
  terraform apply --auto-approve -target=module.ecs_service.aws_ecr_repository.main

  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$registry"
  docker pull --platform linux/amd64 "$SOURCE_IMAGE"
  docker tag "$SOURCE_IMAGE" "$container_image"
  docker push "$container_image"
}

# Function to apply terraform infrastructure in a directory
apply_terraform() {
  local dir=$1

  echo ""
  pushd "$dir"
  echo ""

  terraform workspace select "$AWS_ENV"

  if [[ "$dir" == "$app_dir" ]]; then
    push_image
  fi

  terraform apply --auto-approve

  echo ""
  popd
  echo ""
}

# Function to destroy terraform infrastructure in a directory
destroy_terraform() {
  local dir=$1

  echo ""
  pushd "$dir"
  echo ""

  terraform workspace select "$AWS_ENV"
  terraform destroy --auto-approve

  echo ""
  popd
  echo ""
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

    # Apply app directory last
    apply_terraform $app_dir

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

    # Destroy app directory first
    destroy_terraform $app_dir

    # Destroy cluster directory next
    destroy_terraform $cluster_dir

    # Destroy vpc directory last
    destroy_terraform $vpc_dir

    exit 0
    ;;
  --test|-T)
    DNS_NAME=$(aws elbv2 describe-load-balancers \
      --names "$AWS_ENV--$project_name--lb" \
      --query 'LoadBalancers[0].DNSName' \
      --output text \
      --region $AWS_REGION)

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
        echo ""
        pushd "$app_dir/load_test"
        echo ""
        
        k6 run -e LB_DNS=$DNS_NAME index.js

        echo ""
        popd
        echo ""
      ;;
    esac
    ;;
  *)
    echo "Usage: $0 [--apply|-A] [--destroy|-D] [--test|-T <system|cpu|k6>]"
    exit 1
    ;;
esac
