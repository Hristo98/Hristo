#Provider 
provider "aws"{
    region = "ap-southeast-1"
    profile = "default"
}

#Security groups
resource "aws_security_group" "ELB-SG" {
    name = "ELB-SG"

    #Incoming traffic
    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Outgoing traffic
    egress {
        from_port   = 0
        to_port     = 0        
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"] 
    }
  
}

#Create first web server
resource "aws_instance" "First_Webserver" {
    ami             = "ami-094bbd9e922dc515d"
    instance_type   = "t2.micro"
    key_name        = "Web-key"
    security_groups = ["ELB-SG"]
    availability_zone = "ap-southeast-1a"
    user_data       = <<EOF
    #!/bin/bash
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "Hello, this is my first web server for the assignment" > var/www/html/index.html
    EOF
    tags = {
        Name   = "First_Webserver"
        source = "terraform"
    } 
  
}


#Create second web server
resource "aws_instance" "Second_Webserver" {
    ami             = "ami-094bbd9e922dc515d"
    instance_type   = "t2.micro"
    key_name        = "Web-key"
    availability_zone = "ap-southeast-1b"
    security_groups = ["ELB-SG"]
    user_data       = <<EOF
    #!/bin/bash
    yum install httpd -y
    service httpd start
    chkconfig httpd on
    echo "Hello, this is my second web server for the assignment" > var/www/html/index.html
    EOF
    tags = {
        Name   = "Second_Webserver"
        source = "terraform"
    } 
  
}

