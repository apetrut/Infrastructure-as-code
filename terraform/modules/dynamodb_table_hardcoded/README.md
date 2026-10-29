# DynamoDB Table Module

A terraform module to create a DynamoDB table.

This version of the module module has no variables.

```hcl
module "dynamodb_table" {
  source = "./modules/dynamodb_table_hardcoded"
}

It will return a `table_arn` and `table_name` as outputs.
