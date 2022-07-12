resource "aws_iam_instance_profile" "ec2_profile" {
  name = "image-builder"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name               = "image-builder"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "builder" {
  vpc_id      = "vpc-c4d0f5a3"
  description = "security group for building AMI"
  name        = ""
  tags = {
    Name        = "image-builder-sg"
    Environment = "test"
  }
}

resource "aws_security_group_rule" "from_internet_to_service_on_22" {
  security_group_id = aws_security_group.builder.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "22"
  to_port           = "22"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow ssh access from payment internet to image builder ec2"
}

resource "aws_security_group_rule" "allow_ec2_egress_to_internet_on_443" {
  security_group_id = aws_security_group.builder.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow https egress access from payment app ec2 to internet"
}

resource "aws_security_group_rule" "allow_ec2_egress_to_internet_on_80" {
  security_group_id = aws_security_group.builder.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow http egress access from payment app ec2 to internet"
}

