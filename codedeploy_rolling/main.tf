resource "aws_s3_bucket" "codedeploy" {
  bucket = "${var.service_name}-app-deployment-spec"
  tags = {
    Name = "${var.service_name}-app-deployment-spec"
  }
}


resource "aws_codedeploy_app" "app" {
  name             = "${var.service_name}-app"
  compute_platform = "Server"
  tags = {
    Name        = "${var.service_name}-app"
    Environment = "Test"
  }
}


resource "aws_codedeploy_deployment_group" "app" {
  app_name              = aws_codedeploy_app.app.name
  deployment_group_name = "${aws_codedeploy_app.app.name}-deployment-group"
  service_role_arn      = "arn:aws:iam::483751608719:role/CodeDeployServiceRole"
  load_balancer_info {
    target_group_info {
      name = data.aws_lb_target_group.app.name
    }
  }
  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  deployment_style {
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }
  ec2_tag_set {
    ec2_tag_filter {
      key   = "Cluster"
      type  = "KEY_AND_VALUE"
      value = "simple-app"
    }
  }
}
