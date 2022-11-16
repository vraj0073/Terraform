
provider "aws" {
region = "us-east-1"
}

variable "instance_port" {

    type = number
    default = 8080
}

output "instance_ip_addr" {
  value = aws_instance.instance.public_ip
}

resource "aws_instance" "instance"{

    ami = "ami-09d3b3274b6c5d4aa"
    instance_type = "t2.micro"
    vpc_security_group_ids = [aws_security_group.instance-security.id]

    user_data = <<-EOF
                echo "Hello" > index.xhtml
                nohup busybox httpd -f -p ${instance_port} &
                EOF
        
    user_data_replace_on_change = "true"


    tags = {

        Name = "vraj-instance"
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