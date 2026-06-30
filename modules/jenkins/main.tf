resource "aws_instance" "jenkins_ec2_instance_ip" {
  ami           = var.ami_id
  instance_type = var.instance_type
  tags = {
    Name = var.tag_name
  }
  key_name                    = "jenkins_key"
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_for_jenkins
  associate_public_ip_address = var.enable_public_ip_address
  user_data = var.user_data_install_jenkins
}

resource "aws_key_pair" "jenkins_ec2_instance_public_key" {
  key_name   = "jenkins_key"
  public_key = var.public_key
}

resource "aws_eip" "jenkins_eip" {
  instance = aws_instance.jenkins_ec2_instance_ip.id
  depends_on = [aws_instance.jenkins_ec2_instance_ip]
}

