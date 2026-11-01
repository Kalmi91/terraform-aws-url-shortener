terraform {
  # Remote state in S3 with DynamoDB state locking.
  # Backend settings are environment-specific and supplied at init time:
  #   terraform init -backend-config=environments/dev/backend.hcl
  # See environments/*/backend.hcl.example for the values.
  backend "s3" {}
}
