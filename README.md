Elastic Search Cluster on AWS using Terraform
=============

This project will create an elasticsearch cluster. It will communicate with it via private ip addresses. This requires a VPN to your AWS VPC or alternatively running terraform within your VPC.

## Requirements

* Terraform >= v0.4
* An ubuntu AWS AMI with Java and Elasticsearch, see [packer-elastic-search](https://github.com/nadnerb/packer-elastic-search)
* Elasticsearch IAM profile called elasticSearchNode with [EC2 permissions](https://github.com/elastic/elasticsearch-cloud-aws#recommended-ec2-permissions)

## Installation

* install [Terraform](https://www.terraform.io/) and add it to your PATH.
* clone this repo.

## Configuration

Create a configuration file such as `~/.aws/default.tfvars` which includes:

```
aws_access_key="<your aws access key>"
aws_secret_key="<your aws access secret>"
key_name="<your private key name>"
```

Modify the `variables.tf` file, replacing correct values for aws_amis for your region like:

```
variable "aws_amis" {
  default = {
		ap-southeast-2 = "ami-xxxxxxx"
  }
}
```

Modify the `variables.tf` file, replacing correct values for aws_vpcs for your region like:

```
variable "aws_vpcs" {
	default = {
		ap-southeast-2 = "vpc-xxxxxxx"
	}
}
```

These variables can be overriden when running terraform like so:

```
terraform dosomethingcool -var 'aws_vpcs.ap-southeast-2=foozie'
```

The variables.tf terraform file can be further modified, for example it defaults to `ap-southeast-2` for the AWS region.

## Using Terraform

Execute the plan to see if everything works as expected.

```
terraform plan -var-file '~/.aws/default.tfvars'
```

If all looks good, lets build our infrastructure!

```
terraform apply -var-file '~/.aws/default.tfvars'
```
