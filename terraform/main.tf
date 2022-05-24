provider "aws" {
  region = "us-east-2"
  default_tags {
    tags = {
      Environment = "dev"
      Terraform   = true
    }
  }
}

resource "aws_network_interface" "challenge_webserver" {
  subnet_id = "subnet-00ed9737a09813375"
  security_groups = ["sg-026d277d7cffc5428"]
}

data "aws_ami" "debian" {
  name_regex = "^debian-10-amd64*"
  most_recent = true
  owners = ["136693071363"]
  filter {
    name = "architecture"
    values = ["x86_64"]
  }
  filter {
    name = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_instance" "challenge_webserver" {
  ami = data.aws_ami.debian.id
  instance_type = "t2.micro"
  key_name = "debug"
  network_interface {
    network_interface_id = aws_network_interface.challenge_webserver.id
    device_index = 0
  }
  user_data = <<-EOF
    #!/usr/bin/env bash
    sudo su -
    apt-get -y update
    apt-get -y upgrade
    apt-get -y install apache2
    echo -n 'PGh0bWw+CjxoZWFkPgo8dGl0bGU+SGVsbG8gV29ybGQ8L3RpdGxlPgo8L2hlYWQ+Cjxib2R5Pgo8aDE+SGVsbG8gV29ybGQhPC9oMT4KPC9ib2R5Pgo8L2h0bWw+Cg==' | base64 --decode > /var/www/html/index.html
    mkdir /etc/apache2/ssl_certs
    rm -fv /etc/apache2/sites-enabled/*.conf
    echo -n 'PFZpcnR1YWxIb3N0ICo6ODA+CiAgICAgICAgU2VydmVyQWRtaW4gd2VibWFzdGVyQGxvY2FsaG9zdAogICAgICAgIERvY3VtZW50Um9vdCAvdmFyL3d3dy9odG1sCiAgICAgICAgRXJyb3JMb2cgJHtBUEFDSEVfTE9HX0RJUn0vZXJyb3IubG9nCiAgICAgICAgQ3VzdG9tTG9nICR7QVBBQ0hFX0xPR19ESVJ9L2FjY2Vzcy5sb2cgY29tYmluZWQKICAgICAgICBSZXdyaXRlRW5naW5lIE9uCiAgICAgICAgUmV3cml0ZUNvbmQgJXtIVFRQU30gb2ZmCiAgICAgICAgUmV3cml0ZVJ1bGUgXiBodHRwczovLyV7SFRUUF9IT1NUfSV7UkVRVUVTVF9VUkl9CjwvVmlydHVhbEhvc3Q+CjxWaXJ0dWFsSG9zdCAqOjQ0Mz4KICAgICAgICBTZXJ2ZXJBZG1pbiB3ZWJtYXN0ZXJAbG9jYWxob3N0CiAgICAgICAgRG9jdW1lbnRSb290IC92YXIvd3d3L2h0bWwKICAgICAgICBFcnJvckxvZyAke0FQQUNIRV9MT0dfRElSfS9lcnJvci5sb2cKICAgICAgICBDdXN0b21Mb2cgJHtBUEFDSEVfTE9HX0RJUn0vYWNjZXNzLmxvZyBjb21iaW5lZAogICAgICAgIFJld3JpdGVFbmdpbmUgT24KICAgICAgICBPcHRpb25zICtTeW1MaW5rc0lmT3duZXJNYXRjaAogICAgICAgIFNTTEVuZ2luZSBvbgogICAgICAgIFNTTENlcnRpZmljYXRlRmlsZSAvZXRjL2FwYWNoZTIvc3NsX2NlcnRzL2NlcnQucGVtCiAgICAgICAgU1NMQ2VydGlmaWNhdGVLZXlGaWxlIC9ldGMvYXBhY2hlMi9zc2xfY2VydHMva2V5LnBlbQogICAgICAgIFNTTFByb3RvY29sICtUTFN2MS4xICtUTFN2MS4yCjwvVmlydHVhbEhvc3Q+Cg==' | base64 --decode > /etc/apache2/sites-enabled/challenge_server.conf
    ip_addr="$(ip addr | grep -oP 'inet[[:blank:]]+\d{1,3}(.\d{1,3}){3}' | grep -v 127\.0\.0\.1 | sort | uniq | awk '{print $2}' | tr '.' '-')"
    openssl req -x509 -newkey rsa:4096 -keyout /etc/apache2/ssl_certs/key.pem -out /etc/apache2/ssl_certs/cert.pem -sha256 -days 365 -subj "/CN=ec2-$ip_addr.us-east-2.compute.amazonaws.com" -nodes
    a2enmod rewrite
    a2enmod ssl
    systemctl restart apache2
    EOF
  tags = {
    component = "webserver"
    reason    = "brent_challenge"
  }
}

resource "time_sleep" "wait_time" {
  depends_on = [aws_instance.challenge_webserver]
  create_duration = "120s"
}

resource "null_resource" "sleeping" {
  depends_on = [time_sleep.wait_time]
}

resource "null_resource" "http_to_https" {
  depends_on = [null_resource.sleeping]
  provisioner "local-exec" {
    command = "curl http://${aws_instance.challenge_webserver.public_dns} 2>&1 | grep '302 Found'"
  }
}

resource "null_resource" "hello_world" {
  depends_on = [null_resource.http_to_https]
  provisioner "local-exec" {
    command = "curl --insecure https://${aws_instance.challenge_webserver.public_dns} 2>&1 | grep 'Hello World!'"
  }
}

output "public_dns" {
  value = aws_instance.challenge_webserver.public_dns
}

output "http_to_https" {
  value = null_resource.http_to_https
}

output "hello_world" {
  value = null_resource.hello_world
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "local" {
  }
}
