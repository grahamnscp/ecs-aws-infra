# ecs-aws-infra
AWS infrastructure for CDP ECS deployment

## Deploy cluster
Modify parameters in tf/variables.tf as required
Note that a route53 hosted zone id is required

Modify variables:
```
  name_prefix = "mycdp"
  tag_owner = "myusername"
  tag_purpose = "test"
  tag_enddate = 01232022
  aws_key_pair_name = "mysshkeyname"
  route53_domainname = "example.com"
  route53_zone_id = "XXXXXXXXXXXXXXXXXXXX"
  ip_cidr_me = "XXX.XXX.XXX.XXX/32"
  ip_cidr_me_vpn = "XXX.XXX.XXX.XXX/32"
```

Deploy the infrastructure on EC2:
```
(terraform init)
terraform plan
terraform apply
```

Check terraform output is working:
```
terraform output
```

## Generate ansible hosts and internal dns docker image
Edit generate-hosts-file.sh to change DOCKERHUB_USER=mydockerhubuser

This script used the terraform output to collect the deploy values
and uses the following template files subsituting values for the tags "##TAGNAME##"
```
  ansible/hosts.template
  ansible/working-files/resolv.conf.template
  bind-docker/configs/named.conf.cdp.template
  bind-docker/varbind/cdp/db.reversesubnet.in-addr.arpa.template
  bind-docker/varbind/cdp/subdomain.domain.db.template
```

check required values in ansible/hosts file:
```
  ansible_ssh_private_key_file = "~/.ssh/mysshkey"
  centos_password = mycentospassword
  dockerhub_user = mydockerhubuser
  ecs_node_count = 2
```

Run the script and check generated files look okay, if edit the .template files and rerun:
./generate-hosts-file.sh

## Ansible playbook
```
cd ansible
time ansible-playbook -i hosts site.yml
```

Use ssh key to login as centos user



