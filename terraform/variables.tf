variable "aws_region" {
  default = "ap-south-1"
}

variable "subnets" {
  description = "List of subnets for ECS tasks"
  type        = list(string)
}

variable "security_groups" {
  description = "Security groups to assign to the ECS service"
  type        = list(string)
}

