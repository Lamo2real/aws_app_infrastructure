
# --- PROVIDER CONFIGURATION ---
provider "aws" {
    profile = "default" #this is set to the default student user 
    region = "eu-central-1"
}



# Network 
# --- VPC ---

resource "aws_vpc" "flexicharge_vpc" {
    cidr_block = "10.0.0.0/16"

    tags = {
        name = "EC2-to-RDS-VPC"
    }
}



#  & --- subnet ---

resource "aws_subnet" "public_subnet" {
    
    vpc_id            = aws_vpc.flexicharge_vpc.id
    availability_zone = "eu-central-1a"
    cidr_block        = "10.0.1.0/24"

    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_subnet" "private_subnet_1" {

    vpc_id            = aws_vpc.flexicharge_vpc.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "eu-central-1b"

    tags = {
        Name = "Private Subnet-1"
    }
}

resource "aws_subnet" "private_subnet_2" {

    vpc_id            = aws_vpc.flexicharge_vpc.id
    cidr_block        = "10.0.4.0/24"
    availability_zone = "eu-central-1c"

    tags = {
      Name = "private Subnet-2"
    }
}




# --- INTERNET GATEWAY ---
# Attach the Internet Gateway to the VPC for public subnet access

resource "aws_internet_gateway" "ig_two_tier" {
    
    vpc_id = aws_vpc.flexicharge_vpc.id

    tags = {
        Name = "Internet Gateway for EC2 to RDS VPC"
    }
}




# --- ROUTE TABLES ---

resource "aws_route_table" "public_route_table" {

    vpc_id = aws_vpc.flexicharge_vpc.id

    tags = {
      Name = "Public route table"
    }
}

#public subnet assoiced with the subnet
resource "aws_route_table_association" "public_route_table_association_fc" {
    
    subnet_id = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_route_table.id 

}

#routing internet to public subnet
resource "aws_route" "public_route" {
    
    route_table_id = aws_route_table.public_route_table.id
    destination_cidr_block = "0.0.0.0/0" # this is default so that internet user can enter through this route table and not the privet one
    gateway_id = aws_internet_gateway.ig_two_tier.id

}

#private route tavle withpout "direct" internet access, its basically indirect throught the other table
resource "aws_route_table" "private_route_table" {
    
    vpc_id = aws_vpc.flexicharge_vpc.id

    tags = {
        Name = "private route table"
    }
}

#private subnet associated with the public subnet 
resource "aws_route_table_association" "private_route_table_association_1" {

    subnet_id = aws_subnet.private_subnet_1.id
    route_table_id = aws_route_table.private_route_table.id

}

resource "aws_route_table_association" "private_route_table_association_2" {
    
    subnet_id = aws_subnet.private_subnet_2.id
    route_table_id = aws_route_table.private_route_table.id

}




# --- SECURITY GROUPS --- & --- EC2 INSTANCE ---

#configure EC2 instance
resource "aws_instance" "app_server" {
    
    ami = "ami-0084a47cc718c111a"
    instance_type = "c5.4xlarge"
    subnet_id = aws_subnet.public_subnet.id
    associate_public_ip_address = false
    key_name = "ec2_keypair"

    tags = {
      Name = "EC2 for RDS"
    }

    security_groups = [ aws_security_group.sg_for_ec2.id ]

}

resource "aws_eip" "elastic_ip_fc" {

    instance = aws_instance.app_server.id
  
}

output "EIP" {

    value = aws_eip.elastic_ip_fc.public_ip
  
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


# --- RDS INSTANCE --- & --- security group --- 
# Creating RDS Instance in the private Subnet and security group

resource "aws_db_subnet_group" "rds_subnet_group" {

    name = "db-subnet-group"
    subnet_ids = [ 
        aws_subnet.private_subnet_1.id,
        aws_subnet.private_subnet_2.id 
        ]
    
}

resource "aws_security_group" "sg_for_rds" {
    name   = "db-sg"
    vpc_id = aws_vpc.flexicharge_vpc.id

    ingress {
        from_port   = 3306
        to_port     = 3306
        protocol    = "tcp"
        security_groups = [aws_security_group.sg_for_ec2.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

data "aws_secretsmanager_secret_version" "creds" {
  secret_id = "db-creds-v1"
}

locals {
    db_creds = jsondecode(
        data.aws_secretsmanager_secret_version.creds.secret_string
    )
}

resource "aws_db_instance" "db_fc_instance" {
    
    allocated_storage       = 10
    storage_type            = "gp2"
    engine                  = "mysql"
    engine_version          = "5.7"
    instance_class          = "db.t3.micro"
    db_name                 = "dbdatabase"
    username                = local.db_creds.username # this is stored in aws secrets manager
    password                = local.db_creds.password # this as well... we fetch it using the local variables starting on row 228 -> 236
    parameter_group_name    = "default.mysql5.7"
    skip_final_snapshot     = true
    db_subnet_group_name    = aws_db_subnet_group.rds_subnet_group.name
    

    #attaching the db security group
    vpc_security_group_ids = [ aws_security_group.sg_for_rds.id ]
    tags = {
      Name = "ec2_to_mysql_rds"
    }

}




# --- OUTPUTS ---

# Output EC2 public IP 
output "ec2-publicip" {
    value = aws_instance.app_server.public_ip
}

