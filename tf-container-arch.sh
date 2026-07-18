#!/bin/bash

# Arrays to hold directories
PROJECT_NAME="container-arch"

VPC_DIR="$HOME/git/$PROJECT_NAME--aws-vpc"
CLUSTER_DIR="$HOME/git/$PROJECT_NAME--aws-ecs-cluster"
APP1_DIR="$HOME/git/$PROJECT_NAME--aws-ecs-app"

AWS_ACCOUNT="150100906110"
AWS_ENV="dev"

GIT_COMMIT_HASH=$(git rev-parse --short HEAD)

# Terraform files live in a "terraform" subdirectory of each repo
TF_SUBDIR="terraform"

export AWS_REGION="us-east-2"
export AWS_PAGER=""

# Point the "latest" tag at an already-pushed image (by commit hash),
# server-side, so no image layers are re-uploaded.
retag_latest() {
  local repo_name=$1

  local manifest
  manifest=$(aws ecr batch-get-image \
    --repository-name "$repo_name" \
    --image-ids imageTag="$GIT_COMMIT_HASH" \
    --query 'images[0].imageManifest' \
    --output text)

  # Re-putting an unchanged tag returns ImageAlreadyExistsException; ignore it.
  aws ecr put-image \
    --repository-name "$repo_name" \
    --image-tag latest \
    --image-manifest "$manifest" >/dev/null 2>&1 || true
}

# Register a new task definition revision pointing at the freshly pushed
# image, roll the service onto it, and wait for it to stabilize.
deploy_service() {
  local service_name=$1
  local container_name=$2
  local new_image=$3
  local cluster_name="$AWS_ENV--$PROJECT_NAME--ecs-cluster"

  echo "Registering new task definition revision for $service_name"

  local current_task_def_arn
  current_task_def_arn=$(aws ecs describe-services \
    --cluster "$cluster_name" --services "$service_name" \
    --query 'services[0].taskDefinition' --output text)

  # Clone the current revision, swap the image, carry the tags over
  # (--include TAGS returns them as a sibling of .taskDefinition), and strip
  # the read-only fields that register-task-definition rejects.
  local new_task_def
  new_task_def=$(aws ecs describe-task-definition \
    --task-definition "$current_task_def_arn" \
    --include TAGS \
    | jq --arg IMAGE "$new_image" --arg NAME "$container_name" '
        (.tags // []) as $tags
        | .taskDefinition
        | .containerDefinitions |= map(if .name == $NAME then .image = $IMAGE else . end)
        | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
              .compatibilities, .registeredAt, .registeredBy)
        | .tags = $tags
      ')

  local new_task_def_arn
  new_task_def_arn=$(aws ecs register-task-definition \
    --cli-input-json "$new_task_def" \
    --query 'taskDefinition.taskDefinitionArn' --output text)

  echo "Updating service to $new_task_def_arn"
  aws ecs update-service \
    --cluster "$cluster_name" --service "$service_name" \
    --task-definition "$new_task_def_arn" >/dev/null

  echo "Waiting for service to become stable"
  # The built-in waiter gives up after 10 minutes (40 x 15s) and is not
  # configurable, so retry it up to 3 times (up to ~30 minutes total).
  local stable=false
  for attempt in 1 2 3; do
    if aws ecs wait services-stable \
      --cluster "$cluster_name" --services "$service_name"; then
      stable=true
      break
    fi
    echo "Waiter timed out (attempt $attempt of 3), retrying..."
  done

  if [[ "$stable" != "true" ]]; then
    echo "Service did not stabilize in time"
    return 1
  fi

  # The deployment circuit breaker rolls back failed deploys, and the waiter
  # then reports "stable" for the OLD version. Verify the active revision is
  # the one we just registered.
  local active_task_def_arn
  active_task_def_arn=$(aws ecs describe-services \
    --cluster "$cluster_name" --services "$service_name" \
    --query 'services[0].taskDefinition' --output text)

  if [[ "$active_task_def_arn" != "$new_task_def_arn" ]]; then
    echo "Deployment was rolled back!"
    echo "  expected: $new_task_def_arn"
    echo "  active:   $active_task_def_arn"
    return 1
  fi

  echo "Deploy complete"
}

# Push the app image to the ECR repository managed by terraform
push_image() {
  local registry="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
  local app1_name="chip"
  local app2_name="app"
  local image1_repo="$registry/$AWS_ENV/$app1_name"
  local image2_repo="$registry/$AWS_ENV/$app2_name"
  local source_image="fidelissauro/chip:v2"

  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$registry"

  # docker pull --platform=linux/amd64 "$source_image"
  # docker tag "$source_image" "$image1_repo:$GIT_COMMIT_HASH"
  # docker push "$image1_repo:$GIT_COMMIT_HASH"
  # retag_latest "$AWS_ENV/$app1_name"

  echo ""
  pushd ../app
  echo ""

  docker buildx build --platform=linux/amd64 -f Dockerfile -t $app2_name .
  docker tag "$app2_name" "$image2_repo:$GIT_COMMIT_HASH"
  docker push "$image2_repo:$GIT_COMMIT_HASH"
  retag_latest "$AWS_ENV/$app2_name"

  echo ""
  popd
  echo ""

  deploy_service "$app2_name" "$app2_name" "$image2_repo:$GIT_COMMIT_HASH"
}

# Function to apply terraform infrastructure in a directory
apply_terraform() {
  local dir=$1

  echo ""
  pushd "$dir/$TF_SUBDIR"
  echo ""

  terraform init
  terraform workspace select "$AWS_ENV"
  terraform apply --auto-approve

  if [[ "$dir" == "$APP1_DIR" ]]; then
    push_image
  fi

  echo ""
  popd
  echo ""
}

# Function to destroy terraform infrastructure in a directory
destroy_terraform() {
  local dir=$1

  echo ""
  pushd "$dir/$TF_SUBDIR"
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
    apply_terraform $VPC_DIR

    # Apply cluster directories next
    apply_terraform $CLUSTER_DIR

    # Apply app directory last
    apply_terraform $APP1_DIR

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
    destroy_terraform $APP1_DIR

    # Destroy cluster directory next
    destroy_terraform $CLUSTER_DIR

    # Destroy vpc directory last
    destroy_terraform $VPC_DIR

    exit 0
    ;;
  --test|-T)
    DNS_NAME=$(aws elbv2 describe-load-balancers \
      --names "$AWS_ENV--$PROJECT_NAME--lb" \
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
        pushd "$APP1_DIR/load_test"
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
