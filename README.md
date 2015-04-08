Elastic Search Cluster on AWS using Terraform
=============

Install [Terraform](https://www.terraform.io/) and add it to your PATH.

Clone this repo.

Create a configuration file such as `~/.aws/default.tfvars`

```
aws_access_key="<your aws access key>"
aws_secret_key="<your aws access secret>"
key_name="<your private key name>"
```

Execute the plan to see if everything works as expected.

```
terraform plan -var-file '~/.aws/default.tfvars'
```

If all looks good, lets build our infrastructure!

```
terraform apply -var-file '~/.aws/default.tfvars'
```
