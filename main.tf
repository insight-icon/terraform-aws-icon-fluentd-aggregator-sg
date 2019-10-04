data "aws_caller_identity" "this" {}
data "aws_region" "this" {}

locals {
  common_tags = {
    "Terraform" = true
    "Environment" = var.environment
  }

  tags = merge(var.tags, local.common_tags)
}

resource "aws_security_group" "agg_sg" {
  name = var.name
  vpc_id = var.vpc_id
  description = "Security group for fluentd aggregator"

  tags = local.tags
}

resource "aws_security_group_rule" "agg_egress" {
  type = "egress"
  security_group_id = aws_security_group.agg_sg.id
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = [
    "0.0.0.0/0"]
}

resource "aws_security_group_rule" "ssh_ingress" {
  count = var.corporate_ip == "" ? 0 : 1

  type = "ingress"
  security_group_id = aws_security_group.agg_sg.id
  cidr_blocks = [
    "${var.corporate_ip}/32"]
  from_port = 22
  to_port = 22
  protocol = "tcp"
}

resource "aws_security_group_rule" "bastion_ssh_ingress" {
  count = var.bastion_security_group == "" ? 0 : 1

  type = "ingress"
  security_group_id = aws_security_group.agg_sg.id
  from_port = 22
  to_port = 22
  protocol = "tcp"
  source_security_group_id = var.bastion_security_group
}

resource "aws_security_group_rule" "consul_ingress" {
  type = "ingress"
  security_group_id = aws_security_group.agg_sg.id
  cidr_blocks = [
    "10.0.0.0/15"]
  from_port = 9100
  to_port = 9100
  protocol = "tcp"
}

resource "aws_security_group_rule" "fluentd_ingress" {
  type = "ingress"
  security_group_id = aws_security_group.agg_sg.id
  cidr_blocks = [
    "10.0.0.0/15"]
  from_port = 24224
  to_port = 24224
  protocol = "tcp"
}