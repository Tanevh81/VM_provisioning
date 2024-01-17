provider "aws" {
  access_key = "$AWS_ACCESS_KEY_ID"
  secret_key = "$AWS_SECRET_ACCESS_KEY"
  region     = "eu-central-1"
}

resource "aws_vpc" "fori-vpc" {
  cidr_block           = "10.10.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "fori-VPC"
  }
}

resource "aws_internet_gateway" "fori-igw" {
  vpc_id = aws_vpc.fori-vpc.id
  tags = {
    Name = "fori-IGW"
  }
}

resource "aws_route_table" "fori-prt" {
  vpc_id = aws_vpc.fori-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fori-igw.id
  }
  tags = {
    Name = "fori-PUBLIC_RT"
  }
}

resource "aws_subnet" "fori-snet" {
  vpc_id                  = aws_vpc.fori-vpc.id
  cidr_block              = "10.10.10.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "fori-SUB-NET"
  }
}

resource "aws_route_table_association" "fori-prt-assoc" {
  subnet_id      = aws_subnet.fori-snet.id
  route_table_id = aws_route_table.fori-prt.id
}

resource "aws_security_group" "fori-pub-sg" {
  name        = "fori-pub-sg"
  description = "fori Public SG"
  vpc_id      = aws_vpc.fori-vpc.id
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
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "fori-server" {
  ami                    = "ami-0dcc0ebde7b2e00db"
  instance_type          = "t2.micro"
  key_name               = "TerraformKey"
  vpc_security_group_ids = [aws_security_group.fori-pub-sg.id]
  subnet_id              = aws_subnet.fori-snet.id
  provisioner "remote-exec" {
    inline = [
      "sudo usermod -aG docker ec2-user", # Add ec2-user to the docker group
      "sudo yum install -y epel-release", # Install EPEL repository (for CentOS/RHEL)
      "sudo yum install -y ansible",      # Install Ansible
    ]
  }
  provisioner "local-exec" {
    command = <<-EOT
      # Navigate to the ansible directory
      cd ansible

      # Install Ansible roles
      ansible-galaxy install -r requirements.yml

      # Run Ansible playbook
      ansible-playbook -i inventory.ini playbook.yml
    EOT

  }
  # Provisioner to pull the Docker image and run a container on the EC2 instance
  provisioner "remote-exec" {
    inline = [
      "sudo docker pull tanevh/wordpress_test",                           # Pull the Docker image
      "sudo docker run -d --name WP_test -p 80:80 tanevh/wordpress_test", # Run the Docker container
    ]
  }

}

output "public_ip" {
  value = aws_instance.fori-server.public_ip
}
