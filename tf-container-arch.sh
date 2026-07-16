#!/bin/bash

# Arrays to hold directories
vpc_dir="$HOME/git/container-arch--aws-vpc"
cluster_dir="$HOME/git/container-arch--aws-ecs-cluster"
app_dir="$HOME/git/container-arch--aws-ecs-app"

REPO_NAME="linuxtips/linuxtips-app"
REPO_EXISTS=$(aws ecr describe-repositories --repository-names $REPO_NAME 2>&1)

export AWS_REGION="us-east-2"

# Function to apply terraform infrastructure in a directory
apply_terraform() {
  local dir=$1

  if [[ "$dir" == "$app_dir" ]]; then
    # Check if ECR repository exists

    if [[ $REPO_EXISTS == *"RepositoryNotFoundException"* ]]; then
      aws ecr create-repository --repository-name $REPO_NAME --output text > /dev/null  

      if [ $? -ne 0 ]; then
        echo "ECR create failed"
        exit 1
      fi
    fi

    # Push "fidelissauro/chip:v2" image to the ECR
    CONTAINER_IMAGE="150100906110.dkr.ecr.$AWS_REGION.amazonaws.com/linuxtips/linuxtips-app:latest"
    docker pull fidelissauro/chip:v2
    docker tag fidelissauro/chip:v2 $CONTAINER_IMAGE
    docker push $CONTAINER_IMAGE
    pushd "$dir/terraform"

  else
    pushd "$dir"
  fi

  terraform workspace select dev
  terraform apply --auto-approve
  popd
}

# Function to destroy terraform infrastructure in a directory
destroy_terraform() {
  local dir=$1

  pushd "$dir"
  if [[ "$dir" == "$app_dir" ]]; then
    if [[ $REPO_EXISTS != *"RepositoryNotFoundException"* ]]; then
      aws ecr delete-repository --repository-name "$REPO_NAME" --force --output text > /dev/null

      if [ $? -ne 0 ]; then
        echo "ECR delete failed"
        exit 1
      fi
    fi
  fi
  
  terraform workspace select dev
  terraform destroy --auto-approve
  popd
}

case $1 in
  --apply|-a)
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
  --destroy|-d)
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
  *)
    echo "Usage: $0 [apply|destroy]"
    exit 1
    ;;
esac
