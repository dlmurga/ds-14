
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.70.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}


resource "aws_s3_bucket" "s3_bucket" {
  bucket = "java-app-ds14"
}

resource "aws_security_group" "allow-ssh" {
  name = "allow-ssh"
  ingress {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow-tomcat" {
  name = "allow-tomcat"
  ingress {
    protocol  = "tcp"
    from_port = 8080
    to_port   = 8080
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol  = "-1"
    from_port = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "buildserver" {
  ami = "ami-03a0c45ebc70f98ea"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  tags = {
    Name = "buildserver"
  }
  key_name = "terraform"

  provisioner "remote-exec" {
    inline = ["echo server is up"]
  }
  connection {
    type = "ssh"
    host = aws_instance.buildserver.public_ip
    user = "ubuntu"
    private_key = file("/root/keys/terraform.pem")
  }

  provisioner "local-exec" {command = "ansible-playbook -i '${self.public_ip}' build.yml"}

}

