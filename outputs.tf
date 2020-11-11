output "url-tomcat" {
  value = "http://${aws_instance.tomcat.public_ip}:8080"
}
