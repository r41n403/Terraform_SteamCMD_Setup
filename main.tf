terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

#Define provider, make sure to configure AWS CLI with Access Key/Secret Access Key, terraform will automatically detect profile if in default aws cli location
provider "aws" {}

# Create a VPC
resource "aws_vpc" "GameServerVPC" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
 tags = {
    Name = "GameServerVPC"
  }

}

#Create internet gateway to access public internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.GameServerVPC.id

  tags = {
    Name = "GameServerIGW"
  }
}

#Create public subnets, pulling from variables.tf file 
resource "aws_subnet" "public_subnets" {
 count      = length(var.public_subnet_cidrs)
 vpc_id     = aws_vpc.GameServerVPC.id
 cidr_block = element(var.public_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Public Subnet ${count.index + 1}"
 }
}

#Create private subnets, pulling from variables.tf file 
resource "aws_subnet" "private_subnets" {
 count      = length(var.private_subnet_cidrs)
 vpc_id     = aws_vpc.GameServerVPC.id
 cidr_block = element(var.private_subnet_cidrs, count.index)
 availability_zone = element(var.azs, count.index)
 
 tags = {
   Name = "Private Subnet ${count.index + 1}"
 }
}

#Create public route table that goes to Internet Gateway
resource "aws_route_table" "gameservervpc_public_rt" {
 vpc_id = aws_vpc.GameServerVPC.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "gameservervpc_public_rt"
 }
}

#Associate public subnets to public route table
resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.gameservervpc_public_rt.id
}

#Get current IP so it can be whitelisted
data "http" "icanhazip" {
  url = "http://icanhazip.com"
}

#Output own IP console to make sure it's correct
output "my_terraform_enviroment_public_ip" {
  value = "${chomp(data.http.icanhazip.body)}"
}

#Create security group that will be used for game server instance
resource "aws_security_group" "allow_steamcmd_instance" {
  name        = "allow_steamcmd_instance"
  description = "SG rules for steamcmd server"
  vpc_id      = aws_vpc.GameServerVPC.id

  tags = {
    Name = "allow_steamcmd_instance"
  }
}

#Allow all inbound to example game server port
resource "aws_vpc_security_group_ingress_rule" "allow_game_port" {
  security_group_id = aws_security_group.allow_steamcmd_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 27015
  ip_protocol       = "udp"
  to_port           = 27015
}

#Create inbound rule for own IP to ssh to server
resource "aws_vpc_security_group_ingress_rule" "allow_admin_ssh" {
  security_group_id = aws_security_group.allow_steamcmd_instance.id
  cidr_ipv4         = "${chomp(data.http.icanhazip.body)}/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

#Allow all outbound
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_steamcmd_instance.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

#Store public key in AWS
resource "aws_key_pair" "steamcmd_key" {
  key_name   = "steamcmd_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCj5/O5yaKmlVqFxtoTM555e1PxG2daflqHbcuEVVTzRlvZ2mo0+rWzYH64zTTIhxP8d2AXf06NgHxttqCHtOJDEYzfwdVt/ouRFNWR1SVR3oCKg3L807L0hLfRhvGNU59NXXJO5kQZoJ+1/b18P79rWV+pKuPR92f4azJakm0dqYRpceXW04UV6n4jDxUJKxe4kDMK2PuLbo97rM5I147exZBLamjPYGUTodvlFDp9fVODplutJxYbiNkPeikKMk/K6/eRS9EHh/REGM0kyKCePum0V2POPMmyG/PLaE+IIOmuWy0KrXHOWiFpu+rSz5QaHEu8mKo4tqAmBdKz6UKp rsa-key-20240411"

}

#output which subnet it's going to be on in console
output "public_subnets" {
  value = aws_subnet.public_subnets[0].id
}

#Create Game Server Instance, assign first public subnet, assign ssh key, security group
resource "aws_instance" "steamcmd_server" {
  ami           = "ami-0a699202e5027c10d"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.public_subnets[0].id
  key_name = aws_key_pair.steamcmd_key.key_name
  user_data = "${file("steamcmd_install.sh")}"
  vpc_security_group_ids = [ aws_security_group.allow_steamcmd_instance.id ]
  tags = {
    Name = "steamcmd_server"
  }
  
}

# Assign elastic IP to instance
resource "aws_eip" "server-ip" {
  instance = aws_instance.steamcmd_server.id
  domain   = "vpc"
}

