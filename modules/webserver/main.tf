resource "aws_default_security_group" "default-sg" {
  
  vpc_id = var.vpc_id

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-default-sg"
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true 
  owners = ["amazon"]
  filter {
    
    name = "name"
    values = [var.image_name]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCoVw0sdOer+yr5OPfQw7MV4NgNI6Ui2FFG8AY+3fkgAdrxkD0nJoVTj5sW245QYZeg1/4l4nc85rutfxAkI9Mry4JSRODgSVEO2t5db1ST6XpYwfEKeuQGdSBxrfEgT88JoZirMqdPFm6FR6ctMhgULCK6DNGxwyfVjYR9VLUbeqwiJFzPRbwd5fqaIBQhrWaGw59zGCBUObyQsY8goa9rc5djZ7thfYUzuanTN6w92fNtsnIlEFf/v1YXA1+fPJ6BFt7Mgm5lEq3kgwUaw/52+petxneGWhYFzaHp5wqWU3Vb+dmVt9vtDVgei7ieCnmP0s9o6N3DAdspp5UdZgnWwAaqj2Sl1ouMtt7HeEMmBc6v63uSdrkPay5fMPwPqePlv8b//OA06Svfd9Ymv6JXZvPQuUFMsf8erw5SHw0WWLOVZAXTGwwSbWfwbUiuOCJlol/AxbOOMWVA5nhd0N7Gu2nOXpmr5HhWheLoWdR8Htvoe7R/3pZp9nUNE4AfHE0= crazyt@win11client"

}

resource "aws_instance" "myapp-server" {
  ami = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id = var.subnet_id

  vpc_security_group_ids = [aws_default_security_group.default_sg_id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  key_name = aws_key_pair.ssh-key.key_name

  user_data = file ("entry-script.sh")
connection {
  
  type = "ssh"
  host = self.public_ip
  user = "ec2-user"
  private_key = file(var.private_key_location)
}
provisioner "remote-exec" {
  inline = [
    "export ENV=dev",
    
    "mkdir newdir"
  ]
}

provisioner "file" {
  source = "entry-script.sh"
  destination = "/home/ec2-user/entry-script-on-ec2.sh"
}
  tags = {
    Name = "${var.env_prefix}-server"
  }


}

