#!/bin/bash

# Setup inicial
set -e

AWS_ACCOUNT="150100906110"
AWS_REGION="us-east-2"
AWS_PAGER=""
AWS_ENV="dev"

PROJECT_NAME="container-arch"
APP_NAME="app"
CLUSTER_NAME="$AWS_ENV--$PROJECT_NAME--ecs-cluster"

REGISTRY="$AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com"
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
IMAGE_REPO="$REGISTRY/$AWS_ENV/$APP_NAME"

# CI App
echo ""
pushd app
echo ""

echo "CI App - Lint"

go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.59.1
golangci-lint run ./... -E errcheck

echo "CI App - Test"

go test -v ./...

echo ""
popd
echo ""

# CI Terraform

echo ""
pushd terraform
echo ""

echo "CI Terraform - Lint"

terraform init
terraform fmt -recursive
terraform validate

echo "CI Terraform - Plan"

terraform plan -out=plan.tfplan --parallelism 2000

echo ""
popd
echo ""

# CI Build App

echo ""
pushd app
echo ""

echo "CI App - Build"

aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"
docker buildx build --platform=linux/amd64 -f Dockerfile -t $APP_NAME .
docker tag "$APP_NAME" "$IMAGE_REPO:$GIT_COMMIT_HASH"

echo ""
popd
echo ""

# CD Terraform

echo ""
pushd terraform
echo ""

echo "CI Terraform - Apply"

terraform apply plan.tfplan

echo ""
popd
echo ""

# CD Publish App

echo ""
pushd app
echo ""

docker push "$IMAGE_REPO:$GIT_COMMIT_HASH"

# Point "latest" at the image we just pushed, server-side (no layer re-upload).
# Re-putting an unchanged tag returns ImageAlreadyExistsException; ignore it.
MANIFEST=$(aws ecr batch-get-image \
  --repository-name "$AWS_ENV/$APP_NAME" \
  --image-ids imageTag="$GIT_COMMIT_HASH" \
  --query 'images[0].imageManifest' \
  --output text)

aws ecr put-image \
  --repository-name "$AWS_ENV/$APP_NAME" \
  --image-tag latest \
  --image-manifest "$MANIFEST" >/dev/null 2>&1 || true

echo ""
popd
echo ""

# CD Check App deploy

# Name of the container to update inside the task definition. The terraform
# module sets it to the service name, so it must match that here.
CONTAINER_NAME="$APP_NAME"
NEW_IMAGE="$IMAGE_REPO:$GIT_COMMIT_HASH"

echo "Registering new task definition revision"

# Current task definition attached to the running service
CURRENT_TASK_DEF_ARN=$(aws ecs describe-services \
  --cluster "$CLUSTER_NAME" --services "$APP_NAME" \
  --region "$AWS_REGION" \
  --query 'services[0].taskDefinition' --output text)

# Clone it, swap the image, carry the tags over, and strip the read-only
# fields that register-task-definition rejects. Tags are returned by
# --include TAGS as a sibling of .taskDefinition, so merge them back in.
NEW_TASK_DEF=$(aws ecs describe-task-definition \
  --task-definition "$CURRENT_TASK_DEF_ARN" \
  --region "$AWS_REGION" \
  --include TAGS \
  | jq --arg IMAGE "$NEW_IMAGE" --arg NAME "$CONTAINER_NAME" '
      (.tags // []) as $tags
      | .taskDefinition
      | .containerDefinitions |= map(if .name == $NAME then .image = $IMAGE else . end)
      | del(.taskDefinitionArn, .revision, .status, .requiresAttributes,
            .compatibilities, .registeredAt, .registeredBy)
      | .tags = $tags
    ')

NEW_TASK_DEF_ARN=$(aws ecs register-task-definition \
  --region "$AWS_REGION" \
  --cli-input-json "$NEW_TASK_DEF" \
  --query 'taskDefinition.taskDefinitionArn' --output text)

aws ecs update-service \
  --cluster "$CLUSTER_NAME" --service "$APP_NAME" \
  --task-definition "$NEW_TASK_DEF_ARN" \
  --region "$AWS_REGION" >/dev/null

aws ecs wait services-stable \
  --cluster "$CLUSTER_NAME" --services "$APP_NAME" \
  --region "$AWS_REGION"

echo "Deploy complete"

# app.linuxtips.demo isn't a real domain (Route53 can't host it), so local
# testing resolves it via /etc/hosts; keep it pointed at the ALB's current IP.
AWS_ENV="$AWS_ENV" AWS_REGION="$AWS_REGION" PROJECT_NAME="$PROJECT_NAME" \
  bash "$(dirname "${BASH_SOURCE[0]}")/../local-pipeline/update_etc_hosts.sh"
