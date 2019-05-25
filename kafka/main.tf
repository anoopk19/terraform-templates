provider "aws" {}

resource "aws_iam_role" "kafka-role" {
  name = "${var.env}-kafka-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    environment = "${var.env}"
  }
}

resource "aws_security_group" "kafka-sg" {
  name        = "${var.env}-kafka-sg"
  description = "Access rules to Kafka EC2 Instances"
  vpc_id      = "${var.vpc}"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [""]
    description = "Allow traffic from Home Network"
  }

  ingress {
    protocol    = "tcp"
    from_port   = 9092
    to_port     = 9092
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "kafka-lb-sg" {
  name        = "${var.env}-kafka-lb-sg"
  description = "Access rule to Kafka nodes"

  ingress {
    protocol    = "tcp"
    from_port   = 9092
    to_port     = 9092
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_instance_profile" "kafka-instance-profile" {
  name = "${var.env}-kafka-instance-profile"
  role = "${aws_iam_role.kafka-role.id}"
}

resource "aws_launch_configuration" "kafka-launch-config" {
  name_prefix          = "${var.env}-kafka-launch-config"
  image_id             = "${var.image}"
  ebs_optimized        = true
  key_name             = "Dev Environment"
  instance_type        = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.kafka-instance-profile.id}"
}

resource "aws_autoscaling_group" "kafka-asg" {
  name_prefix          = "${var.env}-kafka-asg-"
  launch_configuration = "${aws_launch_configuration.kafka-launch-config.name}"
  target_group_arns    = ["${aws_lb_target_group.kafka-tg.arn}"]
  min_size             = 3
  max_size             = 3
}

resource "aws_lb" "kafka-lb" {
  name               = "${var.env}-kafka-lb"
  internal           = true
  load_balancer_type = "network"
  security_groups    = ["${aws_security_group.kafka-lb-sg.id}"]

  tags {
    Environment = "${var.env}"
  }
}

resource "aws_lb_target_group" "kafka-tg" {
  name        = "${var.env}-kafka-lb-tg"
  port        = 9092
  protocol    = "tcp"
  vpc_id      = "${var.vpc}"
  target_type = "instance"
}

resource "aws_lb_listener" "kafka-lb-listener" {
  load_balancer_arn = "${aws_lb.kafka-lb.arn}"
  port              = "9092"
  protocol          = "tcp"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.kafka-tg.arn}"
  }
}
