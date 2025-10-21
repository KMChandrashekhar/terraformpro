variable "aws_region" {
  default = "ap-south-1"
}

variable "jenkins_instance_type" {
  default = "t2.medium"
}

variable "app_instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of your AWS key pair"
  default     = "jenkin-tomcat"
}

variable "owner" {
  default = "KMChandrashekhar"
}
