provider "aws" {
  access_key = "AKIA555I5LSSPIAGADNE"
  secret_key = "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"
  region     = "eu-central-1"
}

resource "aws_instance" "vm1" {
  # Amazon Linux 2 AMI (HVM) - Kernel 5.10, SSD Volume Type
  ami           = "ami-0dcc0ebde7b2e00db"
  instance_type = "t2.micro"
  key_name      = "terraform-key"
}

output "public_ip" {
  value = aws_instance.vm1.public_ip
}
output "public_dns" {
  value = aws_instance.vm1.public_dns
}