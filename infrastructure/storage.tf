


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
    multi_az                = true
    
    #attaching the db security group
    vpc_security_group_ids = [ aws_security_group.sg_for_rds.id ]
    tags = {
      Name = "ec2_to_mysql_rds"
    }

}
