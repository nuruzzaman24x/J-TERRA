provider "aws" {
  region = "ap-south-1"
  access_key= "xxxxxxxxxxxxxxxxxxxxxxx"
  secret_key= "xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  
  
}

variable vpc_cidr_block {}
variable subnet_1_cidr_block {}
variable env_prefix {}
variable avail_zone {}
variable my_ip {}
variable instance_type {}




data "aws_ami" "amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

output "ami_id" {
  value = data.aws_ami.amazon-linux-image.id
}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
      Name = "${var.env_prefix}-vpc"
  }
}

resource "aws_subnet" "myapp-subnet-1" {
  vpc_id = aws_vpc.myapp-vpc.id
  cidr_block = var.subnet_1_cidr_block
  availability_zone = var.avail_zone
  tags = {
      Name = "${var.env_prefix}-subnet-1"
  }
}

resource "aws_internet_gateway" "myapp-igw" {
        vpc_id = aws_vpc.myapp-vpc.id

    tags = {
     Name = "${var.env_prefix}-internet-gateway"
   }
}

/*resource "aws_route_table" "myapp-route-table" {
   vpc_id = aws_vpc.myapp-vpc.id

   route {
     cidr_block = "0.0.0.0/0"
     gateway_id = aws_internet_gateway.myapp-igw.id
   }

   tags = {
     Name = "${var.env_prefix}-route-table"
   }
 } */

 resource "aws_default_route_table" "main-rtb" {
    default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }
    tags = {
        Name = "${var.env_prefix}-main-rtb"
    }
}



resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}


resource "aws_key_pair" "ssh-key" {
  key_name   = "mykey"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDuvp3qkVqHE2FIV3/TFL+ET9FRY1NdvJRLf6Dub0laA5TmCNZ/wH5HF0PBdC4ypGWxsGOioPrq6KRGHbn198wD5iZStWxleAb0imoYXTxkfPn/8hMZA1EbOna3S42RqBexl3G9Teb1VAzLmuGiIMUSZeSW/s6/TFYlXWBC4YzXgFXaGbhCGQ/QLgtEN3WO4KbkAtmo854Z1VEn4M+b1DRyATAG2YJbUDxXn/aW9J6pjhXDcf/FGB8+JN9poh78Fn4IuPZCFvGgWmtwMU9/BrttmVFhgyW193h2mwXdW6FZClA6GFsvH6YfKoepQ2suUTsMyT9i/HbUtTA0neaoQhP46FDogfPOcYsB6LAXJfjGHQwSgmNe0zHpUKUvJPgMuq48p+JcPUmbuhbGSquGFCHxyHYwFeZKIy5beh0Y3Bp0Od12zGQ72nGAowkt+zaLfQL4jTivLrt5rzz0dfjq1x/g2WaL5mzN+wc3JPVILyR6EHbSg4UBnAmF21FQIafove7hCPGtqmYkCKCdEZdTyivV5HtcO1arZn25BHiRmRIXa6hpzN0emK08FeZq1kY08BhamHs1i3xhQrGDjnfWOJoCCjO6tnwiFYU30DWIalAr+qBgNnO65dnRvC+ppCZ9V7aak1d6A8jN0uZ8QXX76DrXE4/vVaQf2SBkatH5ArE/zw== root@master01.digitl.com"
 #public_key = file("mykey.pub")

}

output "server-ip" {
    value = aws_instance.myapp-server.public_ip
}

resource "aws_instance" "myapp-server" {
  ami                         = data.aws_ami.amazon-linux-image.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.ssh-key.key_name
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids      = [aws_default_security_group.default-sg.id]
  availability_zone                           = var.avail_zone


user_data = file("entrypoint.sh")

  tags = {
    Name = "${var.env_prefix}-server"
  }

}
