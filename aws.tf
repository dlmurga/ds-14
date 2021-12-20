
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

resource "aws_instance" "buildserver" {
  ami = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  tags = {
    Name = "buildserver"
  }
  key_name = "terraform"
  user_data = <<-EOF
              #!/bin/bash
              sudo -i
              export AWS_ACCESS_KEY_ID=var.aws_ak
              export AWS_SECRET_ACCESS_KEY=var.aws_sk
              echo $AWS_ACCESS_KEY_ID > file.txt
              apt update
              apt install -y default-jdk maven git awscli
              mkdir /java_app
              cd /java_app
              git clone https://github.com/efsavage/hello-world-war.git
              cd /java_app/hello-world-war
              mvn package

              EOF
}
