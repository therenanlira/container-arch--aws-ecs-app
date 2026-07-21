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

# Build, lint, test and push the app image so it is already in ECR before
# terraform runs. The module resolves its container image from the latest
# non-"latest" tag in ECR (see check_ecr_latest_tag.sh); pushing first means
# that lookup sees THIS commit's image right away, so terraform's own apply
# registers the correct task definition revision directly — no separate CLI
# registration step needed, and no lag/revert to an older image next run.
build_and_push_image() {
  local registry="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
  local app_name="app"
  local image_repo="$registry/$AWS_ENV/$app_name"

  # Same hook the CI pipeline runs before building: bootstraps the ECR repo
  # when it doesn't exist yet (e.g. right after the nightly destroy), a no-op
  # otherwise.
  AWS_ENV="$AWS_ENV" APP_NAME="$app_name" bash "$APP1_DIR/ci/pre_build.sh"

  aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$registry"

  echo ""
  pushd ../app
  echo ""

  go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.59.1
  golangci-lint run ./... -E errcheck
  go test -v ./...

  docker buildx build --platform=linux/amd64 -f Dockerfile -t $app_name .
  docker tag "$app_name" "$image_repo:$GIT_COMMIT_HASH"
  docker push "$image_repo:$GIT_COMMIT_HASH"
  retag_latest "$AWS_ENV/$app_name"

  echo ""
  popd
  echo ""
}

# Terraform's own apply already registered the new task definition revision
# and updated the service (the image was pushed moments earlier). Just wait
# for the rollout to stabilize and confirm the circuit breaker didn't roll it
# back to an older revision.
wait_for_deploy() {
  local service_name=$1
  local cluster_name="$AWS_ENV--$PROJECT_NAME--ecs-cluster"

  local expected_task_def_arn
  expected_task_def_arn=$(aws ecs describe-services \
    --cluster "$cluster_name" --services "$service_name" \
    --query 'services[0].taskDefinition' --output text)

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

  local active_task_def_arn
  active_task_def_arn=$(aws ecs describe-services \
    --cluster "$cluster_name" --services "$service_name" \
    --query 'services[0].taskDefinition' --output text)

  if [[ "$active_task_def_arn" != "$expected_task_def_arn" ]]; then
    echo "Deployment was rolled back!"
    echo "  expected: $expected_task_def_arn"
    echo "  active:   $active_task_def_arn"
    return 1
  fi

  echo "Deploy complete"
}

# Function to apply terraform infrastructure in a directory
apply_terraform() {
  local dir=$1

  if [[ "$dir" == "$APP1_DIR" ]]; then
    build_and_push_image
  fi

  echo ""
  pushd "$dir/$TF_SUBDIR"
  echo ""

  terraform init
  terraform workspace select "$AWS_ENV"
  terraform apply --auto-approve

  echo ""
  popd
  echo ""

  if [[ "$dir" == "$APP1_DIR" ]]; then
    wait_for_deploy "app"
  fi
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
