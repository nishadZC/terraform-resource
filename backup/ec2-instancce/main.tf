terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
resource "aws_default_vpc" "default" {}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [aws_default_vpc.default.id]
  }
}
data "aws_ami" "ubuntu_latest_26" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-*-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# data "aws_ami_ids" "ubuntu_latest_26_ids" {
#   owners = ["099720109477"]

#   filter {
#     name   = "name"
#     values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-26.04-amd64-server-*"]
#   }

#   filter {
#     name   = "virtualization-type"
#     values = ["hvm"]
#   }
# }

resource "aws_security_group" "http_sg" {
  name        = "http-sg"
  description = "Security group for HTTP traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "http-sg"
  }
}
resource "aws_elb" "devops-elb" {
  name               = "devops-elb"
  subnets             = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.http_sg.id]
  instances          = values(aws_instance.devops-instance)[*].id

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }
}

resource "aws_instance" "devops-instance" {
  ami                    = data.aws_ami.ubuntu_latest_26.id
  key_name               = var.key_name
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.http_sg.id]
  for_each  = toset(data.aws_subnets.default.ids)
  subnet_id              = each.value
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ubuntu"
    private_key = file(var.aws_key_pair)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install -y apache2",
      "sudo systemctl start apache2",
      "sudo systemctl enable apache2",
      "echo '<h1>Welcome to DevOps World</h1> ${self.public_dns}' | sudo tee /var/www/html/index.html"
    ]
  }
}
# resource "aws_codedeploy_app" "app" {
#   compute_platform = "ECS"
#   name = "my-app"
# }
