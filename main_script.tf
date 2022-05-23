resource "aws_vpc" "vpc" {                        # Creating a Virtual Private Cloud
  cidr_block           = var.VPC_cidr
  enable_dns_support   = "true"                   # A boolean flag to enable/disable DNS support in the VPC
  enable_dns_hostnames = "true"                   # A boolean flag to enable/disable DNS hostnames in the VPC
  enable_classiclink   = "false"
  instance_tenancy     = "default"
}


resource "aws_subnet" "subnet-public-1" {         # Createing a Public Subnet for EC2
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet1_cidr
  map_public_ip_on_launch = "true"                # Indicates that instances launched into the subnet should be assigned a public IP address
  availability_zone       = var.AZ1
}


resource "aws_subnet" "subnet-private-1" {        # Creating a Private subnet for RDS
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet2_cidr
  map_public_ip_on_launch = "false" 
  availability_zone       = var.AZ2
}

resource "aws_subnet" "subnet-private-2" {        # Creating second Private subnet for RDS to be highly available
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.subnet3_cidr
  map_public_ip_on_launch = "false" 
  availability_zone       = var.AZ3
}


resource "aws_internet_gateway" "igw" {           # Creating Internet Gateway to give internet access
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public-crt" {         # Creating route table
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "crta-public-subnet-1" {   # Associating route tabe to public subnet
  subnet_id      = aws_subnet.subnet-public-1.id
  route_table_id = aws_route_table.public-crt.id
}

resource "aws_security_group" "ec2_allow_rule" {                  # Defining security group and openning ports for HTTP, HTTPS, DB and SSH connection
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
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
  vpc_id = aws_vpc.vpc.id
}

resource "aws_security_group" "RDS_allow_rule" {         # Security group for RDS port 3306 connection
  vpc_id = aws_vpc.vpc.id
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.ec2_allow_rule.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow ec2 conecction"
  }
}

resource "aws_db_subnet_group" "RDS_subnet_grp" {          # Create RDS Subnet group in two different AZs
  subnet_ids = ["${aws_subnet.subnet-private-1.id}", "${aws_subnet.subnet-private-2.id}"]
}

resource "aws_db_instance" "db_instance" {                 # Creating RDS mysql instance
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = var.instance_class
  db_subnet_group_name   = aws_db_subnet_group.RDS_subnet_grp.id
  vpc_security_group_ids = ["${aws_security_group.RDS_allow_rule.id}"]
  db_name                = var.MYSQL_DATABASE
  username               = var.MYSQL_USERNAME
  password               = var.MYSQL_PASSWORD
  skip_final_snapshot = true
}


data "template_file" "user_data" {                          # Defining user data file to import environment variables
  template = file("./user_data.tpl")
  vars = {
    db_username      = var.MYSQL_USERNAME
    db_user_password = var.MYSQL_PASSWORD
    db_name          = var.MYSQL_DATABASE
    db_RDS           = aws_db_instance.db_instance.endpoint
  }
}

  
resource "aws_instance" "instance" {                         # Creating EC2 instance using user data defined above 
  ami             = data.aws_ami.linux2.id
  instance_type   = var.instance_type
  subnet_id       = aws_subnet.subnet-public-1.id
  security_groups = ["${aws_security_group.ec2_allow_rule.id}"]

  user_data = data.template_file.user_data.rendered

  key_name = var.key_name                                   # I Used my predefined key-pair to establish SSH connection and log into EC2 instance
  
  tags = {
    Name = "ec2 instance"
  }

  depends_on = [aws_db_instance.db_instance]
}

resource "aws_eip" "eip" {                                   # Creating Elastic IP for EC2 to be public accessible
  instance = aws_instance.instance.id
}


