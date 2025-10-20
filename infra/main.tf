data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Jenkins server
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
              apt-get install -y wget unzip git
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

# App server
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
              EOF
}
