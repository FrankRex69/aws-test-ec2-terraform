variable "aws_profile" {
    type = string
}
variable "aws_region" {
    type = string
}
variable "aws_availability_zone" {
    type = string
}
variable "aws_ami_ec2" {
    type = string
}
variable "aws_key_name" {
    type = string
}


provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}


# 1. Create vpc
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production"
  }
}

# 2. Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

# 3. Create Custom Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}

# 4. Create a Subnet 

resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.aws_availability_zone

  tags = {
    Name = "prod-subnet"
  }
}

# 5. Associate subnet with Route Table
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

# 6. Create Security Group to allow port 22,80,443
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

# 7. Create a network interface with an ip in the subnet that was created in step 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8. Assign an elastic IP to the network interface created in step 7
resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_internet_gateway.gw]
}

# 9. Create Ubuntu server and install/enable apache2
resource "aws_instance" "web-server-instance" {
  ami               = var.aws_ami_ec2
  instance_type     = "t2.micro"
  availability_zone = var.aws_availability_zone
  key_name          = var.aws_key_name

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data              = file("userdata.tpl")
  tags = {
    Name = "web-server"
  }
}

output "server_public_ip" {
    value = aws_instance.web-server-instance.public_ip
}
output "server_private_ip" {
    value = aws_instance.web-server-instance.private_ip
}
