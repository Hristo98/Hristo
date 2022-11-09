#Provider 
provider "aws"{
    region = "us-east-1"
    profile = "default"
}

#Security groups
resource "aws_security_group" "Webserver-SG" {
    name = "Webserver-SG"
    vpc_id = aws_vpc.vpc.id

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
    ami             = "ami-09d3b3274b6c5d4aa"
    instance_type   = "t2.micro"
    key_name        = "hm"
    vpc_security_group_ids = [aws_security_group.Webserver-SG.id]
    subnet_id = aws_subnet.public-subnet-1.id
    availability_zone = "us-east-1a"
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
    ami             = "ami-09d3b3274b6c5d4aa"
    instance_type   = "t2.micro"
    key_name        = "hm"
    subnet_id = aws_subnet.public-subnet-2.id
    availability_zone = "us-east-1b"
    vpc_security_group_ids = [aws_security_group.Webserver-SG.id]
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

variable "vpc-cidr" {
    default = "10.0.0.0/16"
    description = "VPC CIDR Block"
    type = string
  
}

variable "public-subnet-1-cidr" {
    default = "10.0.0.0/24"
    description = "Public Subnet 1 CIDR Block"
    type = string
  
}

variable "public-subnet-2-cidr" {
  default       = "10.0.1.0/24"
  description   = "Public Subnet 2 CIDR Block"
  type          = string
}


variable "private-subnet-1-cidr" {
    default = "10.0.2.0/24"
    description = "Private Subnet 1 CIDR Block"
    type = string
  
}

variable "private-subnet-2-cidr" {
  default       = "10.0.3.0/24"
  description   = "Private Subnet 2 CIDR Block"
  type          = string
}




# Create VPC
# terraform aws create vpc
resource "aws_vpc" "vpc" {
  cidr_block              = "${var.vpc-cidr}"
  instance_tenancy        = "default"
  enable_dns_hostnames    = true
  

  tags      = {
    Name    = "Test VPC"
  }
}

# Create Internet Gateway and Attach it to VPC
# terraform aws create internet gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id    = aws_vpc.vpc.id

  tags      = {
    Name    = "Test IGW"
  }
}

# Create Public Subnet 1
# terraform aws create subnet
resource "aws_subnet" "public-subnet-1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.public-subnet-1-cidr}"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags      = {
    Name    = "Public Subnet 1"
  }
}

# Create Public Subnet 2
# terraform aws create subnet
resource "aws_subnet" "public-subnet-2" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "${var.public-subnet-2-cidr}"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags      = {
    Name    = "Public Subnet 2"
  }
}


# Create Route Table and Add Public Route
# terraform aws create route table
resource "aws_route_table" "public-route-table" {
  vpc_id       = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags       = {
    Name     = "Public Route Table"
  }
}

# Associate Public Subnet 1 to "Public Route Table"
# terraform aws associate subnet with route table
resource "aws_route_table_association" "public-subnet-1-route-table-association" {
  subnet_id           = aws_subnet.public-subnet-1.id
  route_table_id      = aws_route_table.public-route-table.id
}


# Create Private Subnet 1
# terraform aws create subnet
resource "aws_subnet" "private-subnet-1" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = "${var.private-subnet-1-cidr}"
  availability_zone        = "us-east-1a"
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "Private Subnet 1"
  }
}

# Create Private Subnet 2
# terraform aws create subnet
resource "aws_subnet" "private-subnet-2" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = "${var.private-subnet-2-cidr}"
  availability_zone        = "us-east-1b"
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "Private Subnet 2"
  }
}


variable "username" {
    default = "admin"
}

variable "password" {
    default = "pass2022"
}


resource "aws_db_subnet_group" "rdssubnet" {
    name = "database subnet"
    subnet_ids = ["subnet-0c9e76ef1489e1b54", "subnet-0618daeea505f9d06"]
}


# Create a MySQL RDS instance
resource "aws_db_instance" "demo_db" {
    identifier = "mysqldatabase"
    storage_type = "gp2"
    allocated_storage = 20
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t2.micro"
    port = "3306"
    db_name = "myDemoDB"

    username = var.username
    password = var.password
    parameter_group_name = "default.mysql8.0"
    publicly_accessible = false
    deletion_protection = false
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.rdssubnet.id
    tags = {
        Name = "Demo MySQL RD Instance"
    }
}





# Create a new load balancer
resource "aws_elb" "bar" {
  name               = "foobar-terraform-elb"
  subnets = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]

 

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

   health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = [aws_instance.First_Webserver.id, aws_instance.Second_Webserver.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "foobar-terraform-elb"
  }
}


resource "aws_lb_target_group" "alb-example" {
  name        = "tf-example-lb-alb-tg"
  target_type = "alb"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_vpc" "main" {
  cidr_block = "${var.public-subnet-1-cidr}"
}

resource "aws_vpc" "main2" {
  cidr_block = "${var.public-subnet-2-cidr}"
}

#Cloudwatch alarm
resource "aws_cloudwatch_metric_alarm" "ec2_cpu" {
     alarm_name                = "cpu-utilization"
     comparison_operator       = "GreaterThanOrEqualToThreshold"
     evaluation_periods        = "2"
     metric_name               = "CPUUtilization"
     namespace                 = "AWS/EC2"
     period                    = "120"
     statistic                 = "Average"
     threshold                 = "80"
     alarm_description         = "This metric monitors ec2 cpu utilization"
     insufficient_data_actions = []
dimensions = {
       InstanceId = aws_instance.First_Webserver.id
     }

}
