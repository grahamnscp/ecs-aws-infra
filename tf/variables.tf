# Global Variables:

variable "name_prefix" {
  default = "mycdp"
}


# existing hosted zone:
variable "route53_domainname" {
  default = "example.com"
}
variable "route53_zone_id" {
  default = "XXXXXXXXXXXXXXXXXXXX"
}

# tags:
variable "tag_owner" {
  default = "myusername"
}
# instance tags
variable "tag_purpose" {
  default = "infra testing"
}
variable "tag_enddate" {
  default = "01282022"
}

# provider:
variable "aws_region" {
  default = "us-west-1"
}


# security group ips:
variable "ip_cidr_me" {
  default = "XXX.XXX.XXX.XXX/32"
}
variable "ip_cidr_me_vpn" {
  default = "XXX.XXX.XXX.XXX/32"
}


# instances:
variable "aws_ami" {
  # aws ec2 describe-images --owners aws-marketplace --filters Name=product-code,Values=aw0evgkw8e5c1q413zgy5pjce --query 'Images[*].[CreationDate,Name,ImageId]' --filters "Name=name,Values=CentOS Linux 7*" --region us-west-1 --output table | sort -r
  # us-west-1 - CentOS Linux release 7.9.2009 (Core) ref: https://wiki.centos.org/Cloud/AWS
  default = "ami-08d2d8b00f270d03b"
}
variable "aws_instance_type_cdp" {
  default = "m5.4xlarge"
#  default = "r5a.4xlarge"
}
variable "aws_instance_type_infra" {
  default = "t2.medium"
}
#r5.4xlarge	16 cpu	128G mem
#r5.8xlarge	32 cpu	256G mem
#r5.12xlarge	48 cpu	384G mem
#r5.16xlarge	64 cpu	512G mem
variable "aws_instance_type_ecs" {
  default = "t2.medium"
#  default = "r5a.4xlarge"
}
variable "ecs_docker_volume_size" {
  default = "525"
}
variable "ecs_pv_volume_size" {
  default = "1050"
}
variable "ecs_node_count" {
  default = "2"
}
variable "aws_key_pair_name" {
  default = "mysshkeyname"
}


# vpc:
variable "dnsSupport" {
  default = true
}
variable "dnsHostNames" {
  default = true
}
variable "vpcCIDRblock" {
  default = "172.12.0.0/16"
}
variable "subnetCIDRblock" {
  default = "172.12.1.0/24"
}
variable "destinationCIDRblock" {
  default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
#  type = "list"
  default = [ "0.0.0.0/0" ]
}
variable "mapPublicIP" {
  default = true
}
variable "instanceTenancy" {
  default = "default"
}

