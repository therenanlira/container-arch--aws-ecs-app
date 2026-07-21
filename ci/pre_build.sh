#!/usr/bin/env bash
# Ensures the ECR repository exists before the image build/push. On a fresh
# environment (e.g. right after the nightly destroy), the repository doesn't
# exist yet: it's normally created by terraform, but terraform only runs
# AFTER this build step (see pipeline.yaml / tf-container-arch.sh), so we
# bootstrap it here with a targeted apply. A no-op in the common case where
# the repository already exists.
set -euo pipefail

: "${AWS_ENV:?AWS_ENV must be set}"
: "${APP_NAME:?APP_NAME must be set}"

REPO_NAME="${AWS_ENV}/${APP_NAME}"

if aws ecr describe-repositories --repository-names "$REPO_NAME" >/dev/null 2>&1; then
  echo "ECR repository $REPO_NAME already exists, nothing to bootstrap."
  exit 0
fi

echo "ECR repository $REPO_NAME missing (fresh environment) — bootstrapping it."

pushd "$(dirname "${BASH_SOURCE[0]}")/../terraform" >/dev/null

terraform init
terraform workspace select -or-create "$AWS_ENV"
terraform apply -auto-approve \
  -target=module.ecs_service.module.ecr_repository.aws_ecr_repository.main

popd >/dev/null
