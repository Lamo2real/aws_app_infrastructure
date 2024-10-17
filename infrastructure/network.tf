



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
