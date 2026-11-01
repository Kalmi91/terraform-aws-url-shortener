# Serverless URL Shortener, AWS + Terraform

[![Terraform](https://github.com/Kalmi91/terraform-aws-url-shortener/actions/workflows/terraform.yml/badge.svg)](https://github.com/Kalmi91/terraform-aws-url-shortener/actions/workflows/terraform.yml)

A production-style **URL shortener** deployed entirely as **Infrastructure as
Code** with Terraform on AWS. Fully serverless (pay-per-use, fits in the AWS
free tier), with remote state, reusable modules, multi-environment layout, and
a GitHub Actions CI/CD pipeline.

> Built as a portfolio project to demonstrate real-world Terraform + AWS
> practices: module composition, remote state with locking, least-privilege
> IAM, and a `fmt → validate → tflint → tests` pipeline with plan/apply on demand.

---

## Architecture

```
        POST /shorten                 GET /{code}
             │                            │
             ▼                            ▼
   ┌─────────────────────────────────────────────┐
   │        API Gateway (HTTP API, v2)            │
   └───────────────┬───────────────┬─────────────┘
                   │               │
                   ▼               ▼
        ┌────────────────┐   ┌────────────────┐
        │ Lambda:shorten │   │ Lambda:redirect│   (Python 3.12)
        └───────┬────────┘   └───────┬────────┘
                │                    │
                └──────────┬─────────┘
                           ▼
                ┌────────────────────┐
                │  DynamoDB (links)  │   code → url, PAY_PER_REQUEST
                └────────────────────┘

   State backend:  S3 (versioned, encrypted) + DynamoDB (lock table)
```

- **`POST /shorten`** with `{"url": "https://example.com"}` → stores the URL
  under a random 7-char code, returns the short URL.
- **`GET /{code}`** → `301` redirect to the original URL.

## Repository layout

```
.
├── bootstrap/                 # One-time: creates the S3+DynamoDB state backend
├── environments/
│   ├── dev/                   # tfvars + backend.hcl.example for dev
│   └── prod/                  # tfvars + backend.hcl.example for prod
├── modules/
│   ├── dynamodb/              # the links table
│   ├── lambda/                # both functions + per-function least-privilege IAM + log groups
│   └── api_gateway/           # HTTP API, routes, integrations, throttling, access log
├── src/
│   ├── shorten/handler.py     # POST /shorten
│   └── redirect/handler.py    # GET /{code}
├── tests/                     # pytest + moto tests for both handlers
├── requirements-dev.txt
├── main.tf / variables.tf / outputs.tf / providers.tf / versions.tf / backend.tf
├── .github/workflows/terraform.yml   # CI: validate + tests on PRs; plan/apply by hand
├── .tflint.hcl
└── .pre-commit-config.yaml
```

## Prerequisites

- An AWS account with programmatic access (an IAM user/role + access keys).
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  configured (`aws configure`), or `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`
  exported in your shell.

## Deploy

### 1. Bootstrap the remote state backend (once)

```bash
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=YOUR-GLOBALLY-UNIQUE-BUCKET"
# note the two outputs: state_bucket and lock_table
```

Copy `environments/dev/backend.hcl.example` to `environments/dev/backend.hcl`
(git-ignored) and put those values into it (`bucket` and `dynamodb_table`).

### 2. Deploy the application

```bash
cd ..
terraform init -backend-config=environments/dev/backend.hcl
terraform apply -var-file=environments/dev/terraform.tfvars
```

Terraform prints the API endpoint:

```
api_endpoint = "https://abc123.execute-api.eu-central-1.amazonaws.com"
```

### 3. Try it

```bash
API="https://abc123.execute-api.eu-central-1.amazonaws.com"

# Shorten a URL
curl -s -X POST "$API/shorten" \
  -H 'content-type: application/json' \
  -d '{"url":"https://www.hashicorp.com/"}'
# => {"code":"aZ3kP9x","short_url":"https://abc123.../aZ3kP9x"}

# Follow the redirect
curl -i "$API/aZ3kP9x"
# => HTTP/1.1 301 ... location: https://www.hashicorp.com/
```

## CI/CD

`.github/workflows/terraform.yml`:

| Job        | Trigger                                    | What it does                                    |
| ---------- | ------------------------------------------ | ----------------------------------------------- |
| `validate` | PR, push to `main`, manual run             | `terraform fmt -check`, `validate`, `tflint`    |
| `test`     | PR, push to `main`, manual run             | `pytest` + `moto` against both Lambda handlers  |
| `plan`     | manual `workflow_dispatch`, `action: plan`  | `terraform plan` against `dev`                  |
| `apply`    | manual `workflow_dispatch`, `action: apply` | `terraform apply` against `dev` (`dev` environment) |

`validate` and `test` need no cloud credentials. `plan` and `apply` never run
on their own: start them from **Actions → Terraform → Run workflow** and pick
the action.

### One-time setup for plan and apply

CI signs in to AWS with GitHub OIDC, so no AWS keys are stored in the repo.

1. In IAM, add the OIDC provider `token.actions.githubusercontent.com`
   (audience `sts.amazonaws.com`) and a role that
   `repo:Kalmi91/terraform-aws-url-shortener:*` (condition key
   `token.actions.githubusercontent.com:sub`) may assume, with rights to
   manage this stack.
2. Add two repository secrets under **Settings → Secrets and variables →
   Actions**: `AWS_ROLE_ARN` (that role's ARN) and `TF_STATE_BUCKET` (the
   `state_bucket` output from the bootstrap step).

## Cost

Designed to sit inside the **AWS Free Tier** with near-zero traffic:

- **Lambda**, 1M requests/month always free.
- **DynamoDB**, on-demand; 25 GB storage always free.
- **API Gateway (HTTP API)**, 1M requests/month free for the first 12 months,
  then ~\$1.00 / million.
- **S3 / DynamoDB state backend**, pennies at this scale.

For a low-traffic portfolio deployment the running cost is effectively **\$0**.

## Tear down

```bash
terraform destroy -var-file=environments/dev/terraform.tfvars
# then, if you no longer need the state backend:
cd bootstrap && terraform destroy -var="state_bucket_name=YOUR-BUCKET"
```

## Local quality checks

```bash
terraform fmt -recursive
terraform init -backend=false && terraform validate
tflint --init && tflint --recursive
pip install -r requirements-dev.txt && pytest
pre-commit run --all-files   # optional, if pre-commit is installed
```

## License

MIT
