
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
  ami = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  tags = {
    Name = "buildserver"
  }
  key_name = "terraform"

  provisioner "file" {
    source = "/root/.aws/credentials"
    destination = "/home/ubuntu/credentials"
  }
  connection {
    type = "ssh"
    host = aws_instance.buildserver.public_ip
    user = "ubuntu"
    private_key = file("/root/keys/terraform.pem")
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo -i
              apt update
              apt install -y default-jdk maven git awscli
              mkdir /root/.aws
              cp /home/ubuntu/credentials /root/.aws/credentials
              mkdir /java_app
              cd /java_app
              git clone https://github.com/efsavage/hello-world-war.git
              cd /java_app/hello-world-war
              mvn package
              aws s3 cp /java_app/hello-world-war/target/hello-world-war-1.0.0.war s3://java-app-ds14/hello-world-war-1.0.0.war
              EOF

}

resource "aws_instance" "tomcatserver" {
  ami = "ami-0fb653ca2d3203ac1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow-tomcat.id]
  tags = {
    Name = "tomcatserver"
  }
  key_name = "terraform"

  provisioner "file" {
    source = "/root/.aws/credentials"
    destination = "/home/ubuntu/credentials"
  }
  connection {
    type = "ssh"
    host = aws_instance.tomcatserver.public_ip
    user = "ubuntu"
    private_key = file("/root/keys/terraform.pem")
  }
  user_data = <<-EOF
              #!/bin/bash
              sudo -i
              apt update
              apt install -y docker.io awscli
              mkdir /root/.aws
              cp /home/ubuntu/credentials /root/.aws/credentials
              mkdir /java_app
              aws s3 cp s3://java-app-ds14/hello-world-war-1.0.0.war /java_app/s3://java-app-ds14/hello-world-war-1.0.0.war
              docker run -d -p 8080:8080 -v /java_app:/usr/local/tomcat/webapps tomcat:jre8-alpine
              EOF
  depends_on = [aws_instance.buildserver]
}