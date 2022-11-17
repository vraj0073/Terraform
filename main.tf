provider "aws" {

    region = "us-east-1"

}

output "alb_dns_name" {
value = aws_lb.load.dns_name
description = "The domain name of the load balancer"
}

variable "server_port" {
description = "The port the server will use for HTTP requests"
type = number
default = 8080
}

data "aws_vpc" "example" {
    default = "true"
}

data "aws_subnets" "subnet" {

    filter{

        name = "vpc-id"
     values = [data.aws_vpc.example.id]
    }
}

resource "aws_launch_configuration" "launch" {

    image_id = "ami-09d3b3274b6c5d4aa"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.autosacling.id]

     lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "autosacling" {
    name = "autosacling"
    
    ingress{
to_port = 80
from_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]

    }
}
resource "aws_autoscaling_group" "auto"{

    launch_configuration = aws_launch_configuration.launch.name
    max_size = 10
    min_size = 2
    vpc_zone_identifier = data.aws_subnets.subnet.ids
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"

     tag {
key = "Name"
value = "terraform-aws-autosacling"
propagate_at_launch = true
}
}

resource "aws_lb" "load" {
    name = "test-load"
    load_balancer_type = "application"
    subnets = data.aws_subnets.subnet.ids
    security_groups = [aws_security_group.lb-listner.id]
}

resource "aws_security_group" "lb-listner" {

        name = "terraform-alb"

        ingress{
            to_port = 80
            from_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }

        egress{
            to_port = 0
            from_port = 0 
            protocol = "-1"
            cidr_blocks = ["0.0.0.0/0"] 

        }
}

resource "aws_lb_listener" "http" {

    load_balancer_arn = aws_lb.load.arn
    port = 80
    protocol = "HTTP"

    default_action {

        type = "fixed-response"

        fixed_response{
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = 404

        }
    }
}

resource "aws_lb_target_group" "asg" {

    name = "terraform-asg-example"
    port = var.server_port
    protocol = "HTTP"
    vpc_id = data.aws_vpc.example.id

    health_check {

        path = "/"
protocol = "HTTP"
matcher = "200"
interval = 15
timeout = 3
healthy_threshold = 2
unhealthy_threshold = 2

    }
}

resource "aws_lb_listener_rule" "asg" {

    listener_arn = aws_lb_listener.http.arn
    priority = 100

    condition {
path_pattern {
values = ["*"]
}
}
action {
type = "forward"
target_group_arn = aws_lb_target_group.asg.arn
}

}


