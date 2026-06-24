# Fill in 'bucket' and 'dynamodb_table' with the outputs from `bootstrap/`.
bucket         = "CHANGE-ME-url-shortener-tfstate"
key            = "url-shortener/dev/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "terraform-locks"
encrypt        = true
