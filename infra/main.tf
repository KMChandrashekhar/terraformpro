############################################
#  Fetch the latest Ubuntu 22.04 AMI
############################################
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

############################################
#  Security Group for Jenkins Server
############################################
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH, Jenkins (8080), and Ansible access"
  vpc_id      = null  # uses default VPC

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins Web"
    from_port   = 8080
    to_port     = 8080
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
    Name  = "jenkins-sg"
    Owner = var.owner
  }
}

############################################
#  Security Group for Tomcat App Server
############################################
resource "aws_security_group" "app_sg" {
  name        = "tomcat-sg"
  description = "Allow SSH and Tomcat traffic"
  vpc_id      = null

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Tomcat Web"
    from_port   = 8080
    to_port     = 8080
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
    Name  = "tomcat-sg"
    Owner = var.owner
  }
}

############################################
#  Jenkins Server (t2.medium)
############################################
resource "aws_instance" "jenkins" {
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = var.jenkins_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  tags = {
    Name  = "Jenkins-Server"
    Owner = var.owner
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y wget unzip git curl gnupg2
              apt install -y openjdk-21-jdk

              # Install Maven
              apt install -y maven

              # Install Jenkins
              wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | tee /usr/share/keyrings/jenkins-key.asc > /dev/null
              echo deb [signed-by=/usr/share/keyrings/jenkins-key.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
              apt-get update
              apt-get install -y jenkins

              # Install Ansible
              apt install -y python3-pip
              pip3 install ansible

              systemctl enable jenkins
              systemctl start jenkins
              EOF
}

############################################
#  App Server (t2.micro)
############################################
resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = var.app_instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tags = {
    Name  = "Tomcat-App"
    Owner = var.owner
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt install -y openjdk-21-jdk
              apt install -y wget unzip

              # Install Tomcat
              cd /opt
              wget https://downloads.apache.org/tomcat/tomcat-10/v10.1.30/bin/apache-tomcat-10.1.30.tar.gz
              tar -xvzf apache-tomcat-10.1.33.tar.gz
              mv apache-tomcat-10.1.33 tomcat
              chmod +x tomcat/bin/*.sh
              sh tomcat/bin/startup.sh
              EOF
}

############################################
#  Output Public IPs
############################################
output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "app_public_ip" {
  value = aws_instance.app.public_ip
}
