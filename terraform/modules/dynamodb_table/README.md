# DynamoDB Table Module

A terraform module to create a DynamoDB table.

You can use this module by providing table_name and environment as inputs:

```hcl
module "dynamodb_table" {
  source = "./modules/dynamodb_table"

  table_name = "users"
  environment = "dev"
}

And it will return a `table_arn` and `table_name` as outputs.
