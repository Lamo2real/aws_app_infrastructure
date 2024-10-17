


# --- SECURITY GROUPS --- & --- EC2 INSTANCE ---

#configure EC2 instance
resource "aws_instance" "app_server" {
    
    ami = "ami-0084a47cc718c111a"
    instance_type = "c5.4xlarge"
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = true
    key_name = "ec2_keypair"

    tags = {
      Name = "EC2 for RDS"
    }

    security_groups = [ aws_security_group.sg_for_ec2.id ]

}

resource "aws_eip" "elastic_ip_fc" {

    instance = aws_instance.app_server.id
  
}


resource "aws_security_group" "sg_for_ec2" {

    name = "allow_rules"
    vpc_id = aws_vpc.flexicharge_vpc.id

     # Allow HTTPS traffic
    ingress {
        description = "Allow HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Allow custom TCP traffic on port 1025
    ingress {
        description = "Allow TCP on port 1025"
        from_port   = 1025
        to_port     = 1025
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    egress { #outbound traffic from the ec2 insatnce
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
