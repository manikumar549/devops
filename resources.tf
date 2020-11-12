locals {
  vpc_id           = "vpc-18ab4d65"
  subnet_id        = "subnet-0e4bd143"
  ssh_user         = "ubuntu"
  key_name         = "ingnx"
  private_key_path = "ingnx.pem"
}

resource "aws_instance" "tomcat" {
  ami                     = "ami-056940cb2a7bb6d71"
  subnet_id               = "subnet-0e4bd143"
  instance_type           = var.instance
  key_name                = "ingnx"
  associate_public_ip_address = true
  security_groups             = [aws_security_group.tomcat.id]
  


  connection {
    private_key = file(local.private_key_path)
    type        = "ssh"
    user        = local.ssh_user
    host        = aws_instance.tomcat.public_ip
  }

# Enable firewall port 8080 on CentOS
provisioner "remote-exec" {
    inline = [
      "sudo rpm -q iptables-services",
      "sudo yum install firewalld -y",
      "sudo systemctl start firewalld.service",
      "sudo firewall-cmd --state",
      "sudo firewall-cmd --list-all",
      "sudo firewall-cmd --zone=public --permanent --add-service=http",
      "sudo firewall-cmd --zone=public --permanent --add-port 8080/tcp",
      "sudo firewall-cmd --reload",
      "sudo firewall-cmd --list-all",
    ]
  }

# Install OpenJDK and Tomcat with ansible-playbook
provisioner "local-exec" {
    command = <<EOT
      sleep 30s;
      >tomcat.ini;
      echo "[tomcat]" | tee -a tomcat.ini;
      echo "${aws_instance.tomcat.public_ip} ansible_user=${var.ansible_user} ansible_ssh_private_key_file=${var.private_key}" | tee -a tomcat.ini;
      export ANSIBLE_HOST_KEY_CHECKING=False;
      ansible-playbook -u ${var.ansible_user} --private-key ${var.private_key} -i tomcat.ini ../ansible/playbooks/tomcat.yaml
    EOT
  }

  tags = {
    Name     = "tomcat"
    Location = "Verginia"
    "Terraform" : "true"
  }
}

resource "aws_security_group" "tomcat" {
  name   = "tomcat_access"
  vpc_id = local.vpc_id

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






