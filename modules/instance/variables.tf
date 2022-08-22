variable "name" {
  type = string
  description = "tag Name for resources"
}

variable "service" {
  type = string
  description = "tag Service for search ansible dynamic inventory"
}

variable "vpc_name" {
  type = string
  description = "VPC name"
}

variable "Tier" {
  type = string
  description = "Public or Private subnet"
}

variable "ami" {
  type = string
  description = "AMI for ec2 instance"
  default     = "ami-0d527b8c289b4af7f"
}

variable "instance_type" {
  type = string
  description = "Type of instance"
}

variable "instance_count" {
  type = number
  description = "Count instances"
  default = 1
}

variable "key_name" {
  type = string
  description = "Key name for access with SSH"
  default     = "pepe-tf"
}

variable "volume_type" {
  type        = string
  description = "Volume type for root device"
  default     = "gp2"
}

variable "volume_size" {
  type        = string
  description = "Volume size for root device (GB)"
  default     = "100"
}

variable "services_domain_name" {
  type    = string
  default = "pepe-team.tech"
}

variable "ingress_rules" {
  description = "Ingress rules"
  type = map(
    object({
      port = number
      protocol = string
      cidr_block = list(string)
    })
  )
  default = {}
}

variable "ingress_with_source_security_group_id" {
  type = map(object({
    port = number
    protocol = string
    source_security_group_id = string
  }))
}

variable "egress_rules" {
  description = "Egress rules"
  default = {
    http : {
      port = 0
      protocol = "-1"
      cidr_block = ["0.0.0.0/0"]
    }
  }
}

variable "common_sg" {
  type = bool
  default = true
}

variable "default_sg" {
  type = bool
  default = true
}

variable "iam_instance_profile_id" {
  type = string
  default = ""
}

variable "source_dest_check" {
  type = bool
  default = true
}
