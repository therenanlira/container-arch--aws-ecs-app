# Container Architecture on AWS ECS

This repository contains the infrastructure and application code for deploying a containerized application on AWS ECS.

## Repository Structure

container-arch--aws-ecs--app/ .github/ workflows/ dev.yml .gitignore app/ Dockerfile go.mod go.sum main_test.go main.go burn-cpu.sh LICENSE load_test/ index.js pipeline.sh README.md terraform/ .terraform/ environment modules/ modules.json service/ providers/ registry.terraform.io/ terraform.tfstate .terraform.lock.hcl backend.tf data.tf efs.tf environment/ dev/ backend.tfvars iam_role.tf locals.tf main.tf output.tf providers.tf variables.tf test-efs.sh tf-container-arch.sh container-arch--aws-ecs--cluster/ .gitignore .terraform/ .terraform.lock.hcl asg_ondemand.tf asg_spot.tf backend.tf data.tf ecs_cluster.tf environment/ iam_role.tf launch_template_ondemand.tf launch_template_spot.tf LICENSE load_balancer.tf output.tf container-arch--aws-ecs--module/ container-arch--aws-vpc/

## Getting Started

### Prerequisites

- AWS CLI
- Terraform
- Docker

### Setup

1. Clone the repository:

   ```sh
   git clone https://github.com/your-repo/container-arch--aws-ecs.git
   cd container-arch--aws-ecs
   ```

2. Initialize Terraform:

   ```sh
   cd container-arch--aws-ecs--app/terraform
   terraform init
   ```

3. Apply the Terraform configuration deploying all the necessary infrastructure:

   PS: For this step, it is needed to have cloned the repositories [container-arch--aws-ecs--module](git@github.com:therenanlira/container-arch--aws-ecs--module.git) and [container-arch--aws-ecs--cluster](git@github.com:therenanlira/container-arch--aws-ecs--cluster.git) as well.

   ```sh
   ./tf-container-arch.sh
   ```

4. Apply only changes made to the app or to the infrastructure in the repository [container-arch--aws-ecs--app](git@github.com:therenanlira/container-arch--aws-ecs--app.git)

   ```sh
   ./pipeline.sh
   ```

### Scripts

- [tf-container-arch.sh](http://_vscodecontentref_/3): Script to manage the Terraform infrastructure.

### License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct, and the process for submitting pull requests.

## Authors

- **Renan Lira** - _Initial work_ - [RenanLira](https://github.com/RenanLira)

## Acknowledgments

- Hat tip to anyone whose code was used
- Inspiration
- etc
