
# --- PROVIDER CONFIGURATION ---
provider "aws" {
    profile = "default" #this is set to the default student user 
    region = "eu-central-1"
}


# --- OUTPUTS ---

# Output EC2 public IP 
output "ec2-publicip" {

    value = aws_instance.app_server.public_ip

}

output "EIP" {

    value = aws_eip.elastic_ip_fc.public_ip
  
}


