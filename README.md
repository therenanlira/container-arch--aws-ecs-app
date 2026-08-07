# container-arch--aws-ecs-app

Aplicação Go de exemplo e o serviço ECS que a roda, provisionado via o módulo [`ecs_service`](https://github.com/therenanlira/container-arch--aws-modules/tree/main/ecs_service). Consome os states da VPC (`container-arch--aws-vpc`) e do cluster (`container-arch--aws-ecs-cluster`) via `terraform_remote_state`.

Além do serviço, o Terraform daqui cria um volume EFS ([`efs_storage`](https://github.com/therenanlira/container-arch--aws-modules/tree/main/efs_storage)) montado em `/mnt/efs` e dois segredos de exemplo ([`ssm_parameter_store`](https://github.com/therenanlira/container-arch--aws-modules/tree/main/ssm_parameter_store)), injetados no container como variáveis de ambiente. O repositório ECR é criado pelo próprio módulo `ecs_service`.

## Estrutura

| Diretório | Conteúdo |
| --- | --- |
| `app/` | Aplicação Go (`main.go`) e o `Dockerfile` |
| `terraform/` | Infra do serviço, com workspaces por ambiente (`terraform.tfvars`). Hoje só o workspace `dev` está configurado |
| `ci/` | Hooks opcionais do pipeline (`pre_build.sh`, `post_build.sh`, `pre_deploy.sh`, `post_deploy.sh`) |
| `local-pipeline/` | Scripts para rodar o ciclo completo na máquina |
| `load_test/` | Teste de carga com [k6](https://k6.io) |

O diretório `terraform/ecs_health_api_lab/` é uma cópia do lab da aula (aponta para o módulo do professor por caminho local) e **não** é aplicado por este root module — está aqui só como referência.

## Imagem e ordem do deploy

O módulo `ecs_service` não recebe a imagem por variável: ele resolve a tag mais recente (não-`latest`) que existe no ECR. Por isso o **push da imagem tem que acontecer antes do `terraform apply`** — é a ordem que o pipeline segue.

Numa conta recém-destruída o repositório ECR ainda não existe quando o build roda. O `ci/pre_build.sh` cobre esse caso criando só o repositório com um `apply -target`, e é no-op quando ele já existe.

## Pipeline (`.github/workflows/`)

- **`cicd.yaml`** — orquestrador. Em PR `dev -> main` e em push/merge na `main`, aplica o workspace `dev`. Blocos de `prd` já existem, comentados.
- **`pipeline.yaml`** — reusable workflow, mais completo que o dos repos de infra por causa da aplicação:
  - **CI App** — lint e testes Go (só quando há mudança em `app/`).
  - **CI Infra** — `fmt -check` e `validate`.
  - **CI App Build** — `pre_build.sh`, build e push da imagem com a tag do commit, retag do `latest` server-side (sem reenviar layers) e `post_build.sh`.
  - **CI Infra Plan** — `plan` com o workspace selecionado, publicado como artefato.
  - **CD Infra** — baixa o plano, roda `pre_deploy.sh`, `apply`, espera o serviço estabilizar, confere qual task definition ficou ativa e roda `post_deploy.sh`.
- **`destroy.yaml`** — roda `terraform plan -destroy` diariamente às 09:00 UTC (06:00 BRT) e só destrói se houver recursos; também pode ser disparado manualmente. É o **primeiro** do ciclo diário (app 09:00 → cluster 09:20 → vpc 09:40), já que o app depende dos outros dois.

## Uso local

```bash
cd terraform
terraform init
terraform workspace select dev
terraform plan
terraform apply
```

Para o ciclo completo nos três repos (VPC → cluster → app, incluindo build e push da imagem):

```bash
./local-pipeline/tf-container-arch.sh --apply     # sobe tudo
./local-pipeline/tf-container-arch.sh --destroy   # derruba tudo
./local-pipeline/tf-container-arch.sh --test k6   # teste de carga (system | cpu | k6)
```

O host `app.linuxtips.demo` não é um domínio real, então não há como resolvê-lo pelo Route 53. O `local-pipeline/update_etc_hosts.sh` aponta esse nome para o IP atual do ALB no `/etc/hosts` — precisa rodar de novo sempre que o ambiente for recriado, porque o ALB não tem IP fixo.
