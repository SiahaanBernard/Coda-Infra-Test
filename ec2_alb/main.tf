## ALB Resource
resource "aws_lb" "pay" {
  name               = "test-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "payment_ec2" {
  name     = "${var.service_name}-target-group"
  port     = var.service_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.test.id
  health_check {
    path = "/"
  }
  tags = {
    Name = "${var.service_name}-target-group"
  }
}

resource "aws_alb_target_group_attachment" "payment_ec2" {
  for_each         = aws_instance.app
  target_group_arn = aws_lb_target_group.payment_ec2.arn
  target_id        = each.value.id
  port             = var.service_port
}

resource "aws_lb_listener" "payment_lb_http_listener" {
  load_balancer_arn = aws_lb.pay.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_ec2.arn
  }
}

resource "aws_lb_listener_rule" "payment" {
  listener_arn = aws_lb_listener.payment_lb_http_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.payment_ec2.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_security_group" "lb" {
  name        = "payment-lb-sg"
  description = "security group for public payment-lb"
  vpc_id      = data.aws_vpc.test.id
  tags = {
    Name = "payment-lb-sg"
  }
}

resource "aws_security_group_rule" "from_internet_to_payment_lb_on_443" {
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow https ingress access from internet"
}

resource "aws_security_group_rule" "from_internet_to_payment_lb_on_80" {
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow http ingress access from internet"
}

resource "aws_security_group_rule" "to_service_on_service_port" {
  security_group_id        = aws_security_group.lb.id
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = var.service_port
  to_port                  = var.service_port
  source_security_group_id = aws_security_group.app_instance.id
  description              = "allow http egress access from payment-lb to payment-app ec2"
}

## EC2 Instance Resource
resource "aws_instance" "app" {
  for_each             = toset(data.aws_subnets.private.ids)
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  security_groups      = [aws_security_group.app_instance.id]
  subnet_id            = each.value
  ami                  = "ami-04ff9e9b51c1f62ca"
  root_block_device {
    volume_size = "8"
    volume_type = "gp3"
  }
  tags = {
    Name = format("${var.service_name}-%s", each.key)
  }
  user_data = <<EOF
#!/bin/bash
sudo apt update
sudo apt install git
sudo apt install python3-pip -y
exp FLASK_APP=main.py
cd /home/ubuntu && git clone https://github.com/SiahaanBernard/Coda-Simple-App.git
cd /home/ubuntu/Coda-Simple-App && python3 -m pip install -r requirements.txt && python3 main.py
}
EOF
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "payment-app-profile"
  role = aws_iam_role.payment_app_role.name
}

resource "aws_iam_role" "payment_app_role" {
  name               = "payment-app-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.payment_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_security_group" "app_instance" {
  name        = "payment-app-sg"
  description = "security group for payment-app ec2"
  vpc_id      = data.aws_vpc.test.id
  tags = {
    Name = "payment-app-sg"
  }
}

resource "aws_security_group_rule" "from_payment_lb_to_service_on_service_port" {
  security_group_id        = aws_security_group.app_instance.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.service_port
  to_port                  = var.service_port
  source_security_group_id = aws_security_group.lb.id
  description              = "allow http ingress access from payment lb to payment app ec2"
}

resource "aws_security_group_rule" "allow_ec2_egress_to_internet_on_443" {
  security_group_id = aws_security_group.app_instance.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow https egress access from payment app ec2 to internet"
}

resource "aws_security_group_rule" "allow_ec2_egress_to_internet_on_80" {
  security_group_id = aws_security_group.app_instance.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow http egress access from payment app ec2 to internet"
}
