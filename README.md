ELK and Consul Cluster on AWS using Terraform
=============

This project will create an elasticsearch cluster in AWS using multiple availability zones. The cluster is located in a private subnet and communicates via private ip addresses. Logstash is also located in the private subnet.

This uses a bastion server located in a separate default/private VPC that we use for ssh tunneling (over a VPN or you can expose it with a public ip). We then configure the complete stack using [ansible](https://github.com/PageUpPeopleOrg/elk-ansible-configuration).

Kibana and consul servers are located in public subnets.

## Requirements

* Terraform >= v0.5.1
* Elasticsearch IAM profile called elasticSearchNode with [EC2 permissions](https://github.com/elastic/elasticsearch-cloud-aws#recommended-ec2-permissions)

Packer AMI's

We use prebuild Packer AMI's built from these projects:

* [packer-elasticsearch](https://github.com/nadnerb/packer-elastic-search)
* [packer-logstash](https://github.com/nadnerb/packer-logstash)
* [packer-kibana](https://github.com/nadnerb/packer-kibana)
* [packer-consul-server](https://github.com/nadnerb/packer-consul-server)

## Installation

* install [Terraform](https://www.terraform.io/) and add it to your PATH.
* clone this repo.

## Multi AZ

For Multi AZ see this [branch](https://github.com/nadnerb/aws-elasticsearch-cluster/tree/multiaz). Be aware, it does not use elasticsearch shard allocation awareness so there is currently no guarantee of ensuring an index has complete data if an AZ goes down.

## Configuration

Create a configuration file such as `~/.aws/default.tfvars` which can include mandatory and optional variables such as:

```
aws_access_key="<your aws access key>"
aws_secret_key="<your aws access secret>"
key_name="<your private key name>"
key_name="<key name>"

stream_tag="<used for aws resource groups>"

aws_region="ap-southeast-2"
aws_elasticsearch_amis.ap-southeast-2="ami-7ff38945"

# internal hosted zone
hosted_zone_name="<some.internal>"

# vpc and peering
aws_vpc_cidr="<ip range>"
aws_peer_owner_id="<aws user id>"
aws_parent_vpc_id="<parent vpc-id>"
aws_parent_vpc_cidr="172.31.0.0/16"
aws_security_subnet_cidr_a="172.31.250.0/25"
aws_security_subnet_cidr_b="172.31.250.128/25"
# bastion, when on private network this is not necessary
aws_internet_gateway_id="<a gateway id, see bastion.tf to create your own>"

aws_subnet_cidr_a="<subnet a cidr>"
aws_subnet_public_cidr_a="<subnet a public cidr>"
aws_subnet_cidr_b="<subnet b cidr>"
aws_subnet_public_cidr_b="<subnet b public cidr>"

# required by ansible
es_cluster="<cool search cluster>"
es_environment="<you know, for search"
httpuser="<kibana user name>"
httpwd="<password>"
```

You can also modify the `variables.tf` file, replacing correct values for `aws_amis` for your region:

```
variable "aws_elasticsearch_amis" {
  default = {
		ap-southeast-2 = "ami-xxxxxxx"
  }
}
```

These variables can also be overriden when running terraform like so:

```
terraform dosomethingcool -var 'aws_elasticsearch_amis.ap-southeast-2=foozie'
```

The variables.tf terraform file can be further modified, for example it defaults to `ap-southeast-2` for the AWS region.

## Using Terraform

Execute the plan to see if everything works as expected.

```
terraform plan -var-file ~/.aws/default.tfvars -state='environment/development.tfstate'
```

If all looks good, lets build our infrastructure!

```
terraform apply -var-file ~/.aws/default.tfvars -state='environment/development.tfstate'
```

### Multiple security groups

A security group is created using terraform that opens up Elasticsearch and ssh ports. We can also add extra pre-existing security groups to our Elasticsearch instances like so:

```
terraform plan -var-file '~/.aws/default.tfvars' -var 'additional_security_groups=sg-xxxx, sg-yyyy'
```

## TODO

* Finish Bastion config and lock it down
* Clean up and fix variable conventions including elastic ami name
* Clean up security groups
* Remove old scripts, I am using ansible for configuration (Golang does not support ssh proxying through the bastion
  anyway)

## Known issues

* Terraform is not destroying resources correctly which has been made even worse by splitting everything into modules. Currently you need to manually destroy your ec2 instances by hand :( (see [github issue](https://github.com/hashicorp/terraform/issues/1472)). I am currently not using the subnet module which just means I have to destroy the environment twice (fixed in 0.5.1/2).
* Be aware when using a private VPC the `aws_instance` uses `aws_security_group.elastic.id` but in the default VPC it requires `aws_security_group.elastic.name`.
