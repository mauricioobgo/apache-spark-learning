# Terraform — Cluster Dataproc Serverless (opcional)

Este directorio contiene IaC para crear un cluster efímero de Dataproc
con `terraform`. Útil si querés reproducir la infraestructura desde cero.

## Setup

```bash
cd gcp/terraform
terraform init
terraform plan -var="project=tu-proyecto-id"
terraform apply
```

## Cleanup

```bash
terraform destroy
```

## Cuándo usar Serverless vs cluster persistente

- **Serverless** (`gcloud dataproc batches submit`): paga por segundo, ideal
  para jobs batch, ad-hoc, CI/CD.
- **Cluster persistente**: pagás mientras vive, útil para notebooks
  interactivos o jobs que necesitan arranque < 30s.

Este módulo es **Serverless** — más barato para aprender.
