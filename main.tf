
provider "aws" {
region = "us-east-1"
}

variable "instance_port" {

    type = number
    default = 8080
}

data "aws_vpc" "default" {
    default = true
}

data "aws_subnets" "default" {

    filter{

        name = "vpc-id"
        values = [data.aws_vpc.default.id]
    }
}



resource "aws_launch_configuration" "instance"{

    image_id = "ami-09d3b3274b6c5d4aa"
    instance_type = "t2.micro"
    security_groups = [aws_security_group.instance-security.id]
   
    user_data = <<-EOF
                echo "Hello" > index.xhtml
                nohup busybox httpd -f -p ${var.instance_port} &
                EOF     

    

    lifecycle {
create_before_destroy = true
}
    
}

resource "aws_autoscaling_group" "example" {

    launch_configuration = aws_launch_configuration.instance.name
    vpc_zone_identifier = data.aws_subnets.default.ids
    min_size = 2
    max_size = 10

    tag {
key = "Name"
value = "terraform-asg-example"
propagate_at_launch = true
}
}

resource "aws_security_group" "instance-security" {
    name = "terraform security"

    ingress {

        to_port = var.instance_port
        from_port = var.instance_port
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}