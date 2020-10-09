provider aws{
region = var.availabilityZone
}

resource "aws_vpc" "myvpc"{
#region = var.availabilityZone
cidr_block = var.vpcCIDblock
 tags = {
    Name = "myvpc"
  }

}

#create the  public subnet
resource "aws_subnet" "public_subnet"{
vpc_id = aws_vpc.myvpc.id
cidr_block = var.public_subnet
tags = {
    Name = "myvpc_pubicSubnet"
}
}
#create private subnet
resource "aws_subnet" "private_subnet"{
vpc_id = aws_vpc.myvpc.id
cidr_block = var.private_subnet
tags = {
    Name = "myvpc_privateSubnet"
}
}
#create internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myvpc"
  }
}

resource "aws_security_group" "ingress"{
    name = "allow_ssh"
    vpc_id = aws_vpc.myvpc.id
    ingress {
        from_port = 22
        to_port =  22
        protocol = "tcp"
        cidr_blocks = [var.public_subnet,var.private_subnet,"0.0.0.0/0"]

    }
    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "TCP"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
            from_port   = 6443
            to_port     = 6443
            protocol    = "TCP"
            cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
            from_port = 0
            to_port   = 0
            protocol  = "-1"
            self      = true
    }

     egress {
            from_port   = 0
            to_port     = 0
            protocol    = "-1"
            cidr_blocks = ["0.0.0.0/0"]
    } 


}


#Adding the Internetgw to default route table
resource "aws_default_route_table" "aws_route"{
    default_route_table_id = aws_vpc.myvpc.default_route_table_id
    
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
      Name = "publicroute"
  }

}

resource "aws_route_table" "privateroute"{

    vpc_id = aws_vpc.myvpc.id
   
    tags = {
        name = "privateroute"
    }
}


resource "aws_route_table_association" "myvpc_private_subnet"{
    #vpc_id = aws_vpc.myvpc.id
    route_table_id = aws_route_table.privateroute.id
    subnet_id = aws_subnet.private_subnet.id
}

resource "aws_route_table_association" "myvpc_public_subnet"{
   
    route_table_id =  aws_default_route_table.aws_route.default_route_table_id
    subnet_id = aws_subnet.public_subnet.id
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = var.owner_id #its mandatory field
    filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "tls_private_key" "global_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
#to store the private key in the local folder
resource "local_file" "ssh_private_key_pem" {
  filename          = "${path.module}/id_rsa"
  sensitive_content = tls_private_key.global_key.private_key_pem
  file_permission   = "0600"
}
##to store the publickey in the local folder
resource "local_file" "ssh_public_key_openssh" {
  filename = "${path.module}/id_rsa.pub"
  content  = tls_private_key.global_key.public_key_openssh
}

# Temporary key pair used for SSH accesss
resource "aws_key_pair" "airgap_key_pair" {
  key_name_prefix = "${var.prefix}-rancher-"
  public_key      = tls_private_key.global_key.public_key_openssh
}



resource "aws_instance" "bastionvm"{
    
    subnet_id = aws_subnet.public_subnet.id 
    vpc_security_group_ids =  [aws_security_group.ingress.id,]
    instance_type = var.instance_type
    ami           = data.aws_ami.ubuntu.id
    key_name        = aws_key_pair.airgap_key_pair.key_name

   
    tags = {
        name = "publicvm"
    }
}

resource "aws_instance" "inst"{
    count = var.no_of_privatevms
    subnet_id = aws_subnet.private_subnet.id 
    vpc_security_group_ids =  [aws_security_group.ingress.id,]
    instance_type = var.instance_type
    ami           = data.aws_ami.ubuntu.id
    key_name        = aws_key_pair.airgap_key_pair.key_name
    tags = {
        name = "privatevm-${count.index + 1}"
    }
}
 resource "aws_eip" "awseip" {
  vpc = true
  instance                  = aws_instance.bastionvm.id
  associate_with_private_ip = aws_instance.bastionvm.private_ip
 }

