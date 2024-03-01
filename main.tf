 # Create a VPC
resource "aws_vpc" "vpc-terraform"{
    cidr_block = "22.0.0.0/16"
    tags = {
        Name = "VPC-Terraform"
    }
}

#Create a public subnet
resource "aws_subnet" "PublicSubnet"{
    vpc_id = aws_vpc.vpc-terraform.id
    availability_zone = "ap-south-1a"
    cidr_block = "22.0.1.0/24"
    map_public_ip_on_launch = true
    tags = {
        Name = "terra-pub"
    }
}

#create a private subnet
resource "aws_subnet" "PrivSubnet"{
    vpc_id = aws_vpc.vpc-terraform.id
    cidr_block = "22.0.2.0/24"
    
    tags = {
        Name = "terra-pvt"
    }

}


#create IGW
resource "aws_internet_gateway" "myIgw"{
    vpc_id = aws_vpc.vpc-terraform.id
    tags = {
        Name = "terra-igw"
    }
}

# route Tables for public subnet
resource "aws_route_table" "PublicRT"{
    vpc_id = aws_vpc.vpc-terraform.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myIgw.id
    }
    tags = {
        Name = "terra-rt"
    }
}
 

# route table association public subnet 
resource "aws_route_table_association" "PublicRTAssociation"{
    subnet_id = aws_subnet.PublicSubnet.id
    route_table_id = aws_route_table.PublicRT.id
}


// create security_grps for vpc
resource "aws_security_group" "terraform-vpc-sg" {
  name        = "terraform-vpc-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc-terraform.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    # description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-vpc-sg"
  }
}

//create ec2 instance 

resource "aws_instance" "terraform-ec2" {
  ami           = "ami-03bb6d83c60fc5f7c"
  instance_type = "t2.micro"
  # availability_zone = "ap-south-1a"
  subnet_id     = aws_subnet.PublicSubnet.id 
  vpc_security_group_ids = [aws_security_group.terraform-vpc-sg.id]
  tags = {
    Name = "terraform-ec2"
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create a default subnet in the first az if one does not exit
resource "aws_subnet" "subnet_az1" {
  vpc_id = aws_vpc.vpc-terraform.id
  cidr_block = "22.0.3.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = false
}

# create a default subnet in the second az if one does not exit
resource "aws_subnet" "subnet_az2" {
  vpc_id = aws_vpc.vpc-terraform.id
  cidr_block = "22.0.4.0/24"
  availability_zone = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = false
}

//create a rds subnet grp file

resource "aws_db_subnet_group" "rds-subnet-grp"{
  name = "rds_sg"
  subnet_ids = [aws_subnet.PrivSubnet.id,aws_subnet.subnet_az1.id,aws_subnet.subnet_az2.id]
  tags = {
    Name = "rds-subnet-grp"
  }

}

//create a rds file

resource "aws_db_instance" "rds" {
  db_subnet_group_name = aws_db_subnet_group.rds-subnet-grp.name
  engine = "mysql"
  db_name = "terrards"
  allocated_storage = 8
  engine_version = "8.0.28"
  instance_class = "db.t2.micro"
  multi_az = false
  username = "root"
  password = "chaitanya"
  # parameter_group_name = "default.mysql5.7"
  vpc_security_group_ids = [aws_security_group.terraform-rds-sg.id]
  skip_final_snapshot = true
  tags = {
    Name = "terra-rds"
  }

}


// create security grps for rds

resource "aws_security_group" "terraform-rds-sg" {
  name        = "terraform-rds-sg"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.vpc-terraform.id

  ingress {
    description = "TLS from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-rds-sg"
  }
}






