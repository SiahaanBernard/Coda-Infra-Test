## ALB Resource
resource "aws_lb" "pay" {
  name               = "${var.service_name}-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "simple_ec2" {
  name                 = "${var.service_name}-target-group"
  port                 = var.service_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.test.id
  deregistration_delay = "60"
  health_check {
    path                = "/"
    healthy_threshold   = "3"
    interval            = "20"
    unhealthy_threshold = "5"
  }
  tags = {
    Name = "${var.service_name}-target-group"
  }
}

resource "aws_alb_target_group_attachment" "simple_ec2" {
  for_each         = aws_instance.app
  target_group_arn = aws_lb_target_group.simple_ec2.arn
  target_id        = each.value.id
  port             = var.service_port
}

resource "aws_lb_listener" "simple_lb_http_listener" {
  load_balancer_arn = aws_lb.pay.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.simple_ec2.arn
  }
}

resource "aws_lb_listener_rule" "simple" {
  listener_arn = aws_lb_listener.simple_lb_http_listener.arn
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.simple_ec2.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

resource "aws_security_group" "lb" {
  name        = "${var.service_name}-lb-sg"
  description = "security group for public simple-lb"
  vpc_id      = data.aws_vpc.test.id
  tags = {
    Name = "${var.service_name}-lb-sg"
  }
}

resource "aws_security_group_rule" "from_internet_to_simple_lb_on_443" {
  security_group_id = aws_security_group.lb.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow https ingress access from internet"
}

resource "aws_security_group_rule" "from_internet_to_simple_lb_on_80" {
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
  description              = "allow http egress access from simple-lb to simple-app ec2"
}

## EC2 Instance Resource
resource "aws_instance" "app" {
  for_each               = toset(data.aws_subnets.public.ids)
  instance_type          = "t2.micro"
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name
  vpc_security_group_ids = [aws_security_group.app_instance.id]
  subnet_id              = each.value
  ami                    = "ami-0ad401f36dc2038c1"
  root_block_device {
    volume_size = "8"
    volume_type = "gp3"
  }
  tags = {
    Name    = format("${var.service_name}-app-%s", each.value)
    Cluster = "${var.service_name}-app"
  }
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.service_name}-app-profile"
  role = aws_iam_role.simple_app_role.name
}

resource "aws_iam_role" "simple_app_role" {
  name               = "${var.service_name}-app-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "name" {
  role       = aws_iam_role.simple_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "name" {
  role   = aws_iam_role.simple_app_role.name
  policy = data.aws_iam_policy_document.deployment_permision.json
}

resource "aws_security_group" "app_instance" {
  name        = "${var.service_name}-app-sg"
  description = "security group for simple-app ec2"
  vpc_id      = data.aws_vpc.test.id
  tags = {
    Name = "${var.service_name}-app-sg"
  }
}

resource "aws_security_group_rule" "from_simple_lb_to_service_on_service_port" {
  security_group_id        = aws_security_group.app_instance.id
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = var.service_port
  to_port                  = var.service_port
  source_security_group_id = aws_security_group.lb.id
  description              = "allow http ingress access from simple lb to simple app ec2"
}

resource "aws_security_group_rule" "allow_ec2_egress_to_internet_on_443" {
  security_group_id = aws_security_group.app_instance.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = "443"
  to_port           = "443"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow https egress access from simple app ec2 to internet"
}

resource "aws_security_group_rule" "allow_ec2_egress_to_internet_on_80" {
  security_group_id = aws_security_group.app_instance.id
  type              = "egress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow http egress access from simple app ec2 to internet"
}

resource "aws_cloudwatch_metric_alarm" "system" {
  for_each            = toset(data.aws_subnets.public.ids)
  alarm_name          = "${aws_instance.app[each.value].id}_system_check_fail"
  alarm_description   = "System check has failed"
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current.name}:ec2:recover"]
  metric_name         = "StatusCheckFailed_System"
  namespace           = "AWS/EC2"
  dimensions          = { InstanceId : aws_instance.app[each.value].id }
  statistic           = "Maximum"
  period              = "300"
  evaluation_periods  = "2"
  datapoints_to_alarm = "2"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags                = { "Name" : "${var.service_name}_system_check_fail" }
}

resource "aws_cloudwatch_metric_alarm" "instance" {
  for_each            = toset(data.aws_subnets.public.ids)
  alarm_name          = "${aws_instance.app[each.value].id}_instance_check_fail"
  alarm_description   = "Instance check has failed"
  alarm_actions       = ["arn:aws:automate:${data.aws_region.current.name}:ec2:reboot"]
  metric_name         = "StatusCheckFailed_Instance"
  namespace           = "AWS/EC2"
  dimensions          = { InstanceId : aws_instance.app[each.value].id }
  statistic           = "Maximum"
  period              = "300"
  evaluation_periods  = "3"
  datapoints_to_alarm = "3"
  threshold           = "1"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  tags                = { "Name" : "${var.service_name}_system_check_fail" }
}
