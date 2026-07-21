# container-arch--aws-ecs-app

Aplicação Go (Fiber) rodando como serviço ECS, via o módulo [`ecs_service`](https://github.com/therenanlira/container-arch--aws-modules/tree/main/ecs_service) (+ [`efs_storage`](https://github.com/therenanlira/container-arch--aws-modules/tree/main/efs_storage)). Consome o state da VPC e do cluster (`container-arch--aws-vpc`, `container-arch--aws-ecs-cluster`) via `terraform_remote_state`.

## Estrutura

| Diretório/arquivo | Conteúdo |
| --- | --- |
| `app/` | Código Go da aplicação e `Dockerfile` |
| `terraform/` | Infra do serviço ECS (workspaces por ambiente, hoje só `dev`) |
| `ci/` | Scripts de hook do pipeline (ver abaixo) |
| `pipeline/baby-steps.sh` | Sandbox local dos passos de CI/CD, para estudo |
| `load_test/` | Teste de carga com k6 |
| `tf-container-arch.sh` | Script local para aplicar/destruir toda a stack (vpc + cluster + app) |

## Endpoints da aplicação

| Rota | Descrição |
| --- | --- |
| `GET /healthcheck` | Usado pelo health check do target group |
| `GET /version` | Versão da aplicação |
| `GET /arquivos` | Lista arquivos em `/mnt/efs` (EFS) |
| `POST /arquivos` | Grava o corpo da requisição como um arquivo no EFS |
| `GET /arquivos/:uuid` | Lê um arquivo do EFS pelo UUID |
| `GET /printenv` | Lista as variáveis de ambiente do container |

## Pipeline (`.github/workflows/`)

- **`cicd.yaml`** — orquestrador. Em PR `dev -> main` e em push/merge na `main`, roda o pipeline completo para o workspace `dev`. Blocos de `prd` já existem, comentados.
- **`pipeline.yaml`** — reusable workflow, sequencial: lint/test do app + lint/validate da infra → **build e push da imagem** → `terraform plan` → `terraform apply` (único mecanismo de deploy: como a imagem já foi pushada, o Terraform sempre resolve a tag correta e aplica imagem + infra em um único rollout) → wait/verify do serviço ECS.
- **`destroy.yaml`** — roda `terraform plan -destroy` diariamente às 09:00 UTC (06:00 BRT) e só destrói se houver recursos; também pode ser disparado manualmente. Roda **primeiro** no ciclo diário (nada depende do app).

### Hooks (`ci/`)

O template do pipeline chama `ci/pre_build.sh`, `ci/post_build.sh`, `ci/pre_deploy.sh` e `ci/post_deploy.sh` se existirem no repo (senão, no-op) — assim o template compartilhado com `vpc`/`cluster` continua genérico, e qualquer lógica específica deste repo fica isolada aqui.

- **`pre_build.sh`** — bootstrap do repositório ECR: se ele não existir ainda (ex.: logo após o `destroy` diário), faz um `terraform apply -target` só do recurso do ECR antes do build/push, já que o `ecs_service` só resolve a tag da imagem a partir do que já está no ECR.

## Uso local

```bash
# aplica vpc + cluster + app, nessa ordem
./tf-container-arch.sh --apply

# destrói tudo, em ordem reversa
./tf-container-arch.sh --destroy

# testes contra o ambiente
./tf-container-arch.sh --test k6       # roda o load_test/ com k6
```

> `--test system` e `--test cpu` são resquício de uma versão anterior do app (`fidelissauro/chip:v2`) e testam rotas (`/system`, `/burn/cpu`) que não existem no app Go atual — use `k6` ou `curl` direto nas rotas listadas acima.
