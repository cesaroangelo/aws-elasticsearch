# AWS Provider Block
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "${var.region}"
}

resource "aws_vpc" "vpc1" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags {
    Name = "vpc1"
  }
}
resource "aws_internet_gateway" "gw1" {
  vpc_id = "${aws_vpc.vpc1.id}"
}
resource "aws_subnet" "sub1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  cidr_block = "${var.vpc_sub_cidr}"
  availability_zone = "${var.availability_zone_1}"
  tags {
    Name = "sub1"
  }
}
resource "aws_route_table" "route_table1" {
  vpc_id = "${aws_vpc.vpc1.id}"
  route {
     cidr_block = "0.0.0.0/0"
     gateway_id = "${aws_internet_gateway.gw1.id}"
  }
  tags {
     Name = "route-table1"
  }
}
resource "aws_route_table_association" "route_table_association1" {
  subnet_id = "${aws_subnet.sub1.id}"
  route_table_id = "${aws_route_table.route_table1.id}"
}


# Security Group Block for Balancer
resource "aws_security_group" "balancer_sec_grp" {
  name = "balancer_sec_grp"
  description = "Allow ElasticSearch traffic"
  vpc_id = "${aws_vpc.vpc1.id}"
  ingress {
      from_port = 9200
      to_port = 9200
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "balancer_sec_grp"
  }
}

# Security Group Block for Cluster
resource "aws_security_group" "cluster_sec_grp" {
  name = "cluster_sec_grp"
  description = "Allow SSH and ElasticSearch traffic"
  vpc_id = "${aws_vpc.vpc1.id}"
  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
      from_port = 9200
      to_port = 9200
      protocol = "tcp"
      cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "cluster_sec_grp"
  }
}

# AWS Instances Block
resource "aws_instance" "cluster" {
    count = 3
    ami = "${var.ami_value}"
    instance_type = "${var.instance_type}"
    key_name      = "${var.key_name}"
    subnet_id = "${aws_subnet.sub1.id}"
    availability_zone = "${var.availability_zone_1}"
    associate_public_ip_address = true
    vpc_security_group_ids=["${aws_security_group.cluster_sec_grp.id}"]
connection {
        user = "${var.conn_user}"
        key_file = "${var.conn_keyfile}"
    }
    provisioner "file" {
        source = "../files/elasticsearch.repo"
        destination = "/home/ec2-user/elasticsearch.repo"
    }
    provisioner "remote-exec" {
        inline = [
	"sudo rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch",
	"sudo scp elasticsearch.repo /etc/yum.repos.d/elasticsearch.repo",
	"sudo yum update -y",
	"sudo yum install elasticsearch -y && sudo chkconfig --add elasticsearch && sudo service elasticsearch start"
        ]
    }
    tags {
        Name = "Cluster-${count.index}"
    }
}

# Load Balancer Block
resource "aws_elb" "lb_1" {
  name = "load-balancer-elasticsearch"
  security_groups=["${aws_security_group.balancer_sec_grp.id}"]
  subnets = ["${aws_subnet.sub1.id}"]
  listener {
    instance_port = 9200
    instance_protocol = "tcp"
    lb_port = 9200
    lb_protocol = "tcp"
  }
  instances = ["${aws_instance.cluster.*.id}"]
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "load-balancer-elasticsearch"
  }
}
