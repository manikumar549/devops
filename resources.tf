resource "aws_key_pair" "demo_key" {
  key_name   = "tfKeyPair"
  public_key = file(var.public_key)
}

resource "aws_instance" "tomcat" {
  ami                     = var.ami
  instance_type           = var.instance
  key_name                = aws_key_pair.demo_key.key_name
  vpc_security_group_ids  = [
                            aws_security_group.web.id,
                            aws_security_group.ssh.id,
                            aws_security_group.egress-tls.id,
                            aws_security_group.ping-ICMP.id,
	                          aws_security_group.tomcat-server-port.id
  ]

  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  connection {
    private_key = file(var.private_key)
    user        = var.ansible_user
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
    Location = "Mumbai"
    "Terraform" : "true"
  }
}

resource "aws_security_group" "web" {
  name        = "default-web"
  description = "Security group for web that allows web traffic from internet"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-default-vpc"
  }
}

resource "aws_security_group" "ssh" {
  name        = "default-ssh"
  description = "Security group for nat instances that allows SSH and VPN traffic from internet"
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-default-vpc"
  }
}

resource "aws_security_group" "egress-tls" {
  name        = "default-egress-tls"
  description = "Default security group that allows inbound and outbound traffic from all instances in the VPC"
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "egress-tls-default-vpc"
  }
}

resource "aws_security_group" "ping-ICMP" {
  name        = "default-ping"
  description = "Default security group that allows to ping the instance"

  ingress {
    from_port        = -1
    to_port          = -1
    protocol         = "icmp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ping-ICMP-default-vpc"
  }
}

# Allow the Tomcat Apps to receive requests on port 8080
resource "aws_security_group" "tomcat-server-port" {
  name        = "tomcat-server-port"
  description = "Default security group that allows to use port 8080"
  
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_server-tomcat-default-vpc"
  }
}

