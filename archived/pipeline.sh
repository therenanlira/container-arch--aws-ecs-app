#!/bin/zsh

# Initial setup
set -e

export AWS_ACCOUNT_ID=923672208632
export AWS_PAGER=""
export AWS_REGION="us-east-1"
export APP_NAME="linuxtips-app"
export CLUSTER_NAME="linuxtips-ecscluster"
export BRANCH_NAME=$(git branch --show-current)
export BRANCH_NAME_SHORT=$(echo $BRANCH_NAME | cut -d '/' -f 2 | cut -c 1-3)

# App CI
echo "APP - CI"
pushd app/

echo "APP - LINT"
go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.59.1
golangci-lint run ./... -E errcheck

echo "APP - TEST"
go test -v ./...

popd

# Terraform CI
echo "TERRAFORM - CI"
pushd terraform/

echo "TERRAFORM - FORMAT CHECK"
terraform fmt -recursive -check

echo "TERRAFORM CI - TERRAFORM INIT"
terraform init -backend-config="environment/$BRANCH_NAME_SHORT/backend.tfvars"

echo "TERRAFORM - VALIDATE"
terraform validate

popd

# App Build
echo "APP BUILD"
pushd app/

echo "APP BUILD - GET BUILD INFO"
GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
echo "GIT_COMMIT_HASH: $GIT_COMMIT_HASH"

echo "APP BUILD - ECR LOGIN"
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

echo "APP BUILD - CHECK ECR REPOSITORY"
set +e
REPO_NAME="linuxtips/$APP_NAME"
REPO_EXISTS=$(aws ecr describe-repositories --repository-names $REPO_NAME 2>&1)

if [[ $REPO_EXISTS == *"RepositoryNotFoundException"* ]]; then
  echo "APP BUILD - CREATE ECR REPOSITORY"
  aws ecr create-repository --repository-name $REPO_NAME

  if [ $? -ne 0 ]; then
    echo "APP BUILD - CREATE ECR REPOSITORY FAILED"
    exit 1
  fi

else
  echo "APP BUILD - ECR REPOSITORY EXISTS"
fi

set -e

echo "APP BUILD - BUILD"
REPO_TAG="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$REPO_NAME:$GIT_COMMIT_HASH"
docker build --platform linux/amd64 -t app .
docker tag app:latest $REPO_TAG

popd

# App Publish
echo "APP PUBLISH"
pushd app/

echo "APP PUBLISH - PUSH"
docker push $REPO_TAG

popd

# Terraform Apply
echo "TERRAFORM CD"
pushd terraform/

echo "TERRAFORM CD - TERRAFORM PLAN"
terraform plan -var="container_image=$REPO_TAG" -var-file="environment/$BRANCH_NAME_SHORT/terraform.tfvars"

echo "TERRAFORM CD - TERRAFORM APPLY"
terraform apply -auto-approve -var="container_image=$REPO_TAG" -var-file="environment/$BRANCH_NAME_SHORT/terraform.tfvars"

echo "TERRAFORM CD - FORCE ECS TASK UPDATE"
aws ecs update-service --cluster $CLUSTER_NAME --service $APP_NAME --region $AWS_REGION --force-new-deployment --output text > /dev/null

echo "TERRAFORM CD - WAIT FOR ECS SERVICE"
aws ecs wait services-stable --cluster $CLUSTER_NAME --services $APP_NAME --region $AWS_REGION

popd
