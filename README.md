# Personal infra repository

The purpose of this repository is to have my personal AWS infrastructure as a code, so I can easily change and move my infrastructure.

## Configure the codebase:

#### Configure your Terraform backend

- Create a **config.s3.tfbackend** file
- Fill the terraform S3 backend variables ([docs](https://developer.hashicorp.com/terraform/language/settings/backends/s3)):

```
bucket = "your-backend-s3-bucket"
key = "your-tfstate-key"
region = "your-backend-region"
```

- Init your terraform backend with the file configuration

```
terraform init -backend-config="config.s3.tfbackend"
```

#### Configure a **terraform.tfvars.json** file with the following variables:

| Variable                       | Description                                                          |
| ------------------------------ | -------------------------------------------------------------------- |
| region                         | The region of your deployment.                                       |
| repo_name                      | The name of your ECR repository.                                     |
| lambda_name                    | The name of your AWS Lambda function.                                |
| event_rule_schedule_expression | The event rule schedule expression. Default: runs daily at 8:00 UTC. |

#### Configure a **check-links.yaml** file as the example below:

```
ozoneItems:
    - "https://www.ozone.bg/product/the-page-of-your-product/"
    - "https://www.ozone.bg/product/the-page-of-your-next-product/"
ardesItems:
    - "https://ardes.bg/product/the-page-of-the-product/"
ardesSearches:
    - "https://ardes.bg/komponenti/tvardi-diskove/..."
```

Currently only Ozone and Ardes are supported.
