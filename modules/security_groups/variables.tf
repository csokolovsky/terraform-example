variable "vpc_id" {}
variable "service" {}
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

variable "egress_rules" {
  description = "Egress rules"
  default = {
    http : {
      port       = 0
      protocol   = "-1"
      cidr_block = ["0.0.0.0/0"]
    }
  }
}

variable "ingress_with_source_security_group_id" {
  default = {}
  type = map(object({
    port = number
    protocol = string
    source_security_group_id = string
  }))
}