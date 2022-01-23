# Security Groups:

resource "aws_security_group" "infra-instance-sg" {
  name = "infra_instance_sg"
  tags = {
    Name = "${var.name_prefix}_instance_sg"
    owner = "${var.tag_owner}"
    enddate = "${var.tag_enddate}"
  }
  vpc_id = "${aws_vpc.infra-vpc.id}"

#  ingress {
#    from_port = 22
#    to_port = 22
#    protocol = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
  # all ping
  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # allow self
  ingress {
    from_port = 0
    to_port = 0
    protocol = "tcp"
    self = true
  }
  # allow all for internal subnet
  ingress {
    from_port = 0
    to_port = 0
    protocol = -1
    cidr_blocks = ["${aws_subnet.infra-subnet.cidr_block}"]
  }
  # open all for specific ips
  ingress {
    from_port = 0
    to_port = 65535
    protocol = "tcp"
    cidr_blocks = ["${var.ip_cidr_me}","${var.ip_cidr_me_vpn}"]
  }
  # open to all
  #ingress {
  #  from_port = 0
  #  to_port = 0
  #  protocol = -1
  #  cidr_blocks = ["0.0.0.0/0"]
  #}
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

