
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
              apt update
              apt install -y default-jdk maven git
              mkdir /java_app
              cd /java_app
              git clone http://github.com/efsavage/hello-world-war.git
              mvn package
              EOF
}
