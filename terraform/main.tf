terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.45.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_instance_profile" "ec2-profile" {
  name = "jenkins-profile-${var.user}"
  role = "admin"
}

resource "aws_security_group" "jenkins-sec-gr" {
  name = "${var.jenkins_sg}-${var.user}"
  tags = {
    Name = var.jenkins_sg
  }

  dynamic "ingress" {
    for_each = [22, 6443, 80, 3000, 5432, 443, 8081, 30001, 8080, 8090]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k3s-server" {
  ami                    = "ami-04b70fa74e45c3917"  # Ubuntu 22.04 LTS (us-east-1)
  instance_type          = var.instancetype
  key_name               = var.mykey
  vpc_security_group_ids = [aws_security_group.jenkins-sec-gr.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2-profile.name

  root_block_device {
    volume_size = 30  # 30GB disk
  }

  tags = {
    Name = var.tag
  }

  user_data = file("userdata.sh")
}
