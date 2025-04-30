# --- VPC ---
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# --- Public Subnet 1 ---
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = var.availability_zone_1
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1"
  }
}

# --- Public Subnet 2 ---
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = var.availability_zone_2
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2"
  }
}

# --- Private Subnet 1 ---
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = var.availability_zone_1

  tags = {
    Name = "private_subnet_1"
  }
}

# --- Private Subnet 2 ---
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = var.availability_zone_2

  tags = {
    Name = "private_subnet_2"
  }
}

# --- Elastic IP for NAT ---
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

# --- NAT Gateway ---
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "nat_gw"
  }
}

# --- Route Table Public ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# --- Route Table Association Public Subnets ---
resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

# --- Route Table Private ---
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "private_rt"
  }
}

# --- Route Table Association Private Subnets ---
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# --- Security Group for EC2 ---
resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "Allow web traffic and SSH"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
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
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_sg"
  }
}

# --- Security Group for Load Balancer ---
resource "aws_security_group" "lb_sg" {
  name        = "lb_sg"
  description = "Allow HTTP/HTTPS to ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "lb_sg"
  }
}

# --- Load Balancer ---
resource "aws_lb" "app_lb" {
  name               = "wordpress-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [
    aws_subnet.public_subnet_1.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "wordpress-lb"
  }
}

# --- Target Group for EC2 instances ---
resource "aws_lb_target_group" "tg" {
  name     = "wordpress-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

# --- Listener for Load Balancer ---
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# --- EC2 Instances ---
resource "aws_instance" "web_instance_1" {
  ami                         = "ami-0c15e602d3d6c6c4a" # Amazon Linux 2 AMI
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_subnet_1.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name = "wordpress-web-1"
  }
}

resource "aws_instance" "web_instance_2" {
  ami                         = "ami-0c15e602d3d6c6c4a"
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.private_subnet_2.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  tags = {
    Name = "wordpress-web-2"
  }
}

# --- Attach instances to Target Group ---
resource "aws_lb_target_group_attachment" "tg_attachment_1" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_instance_1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "tg_attachment_2" {
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.web_instance_2.id
  port             = 80
}

# Get the default VPC
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Get the first public subnet manually
data "aws_subnet" "default_public_subnet" {
  id = data.aws_subnets.default_subnets.ids[0]
}



# Create the VPC Peering Connection
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = aws_vpc.main_vpc.id
  peer_vpc_id   = data.aws_vpc.default.id
  auto_accept   = true

  tags = {
    Name = "main-to-default"
  }
}
# Add Routes for Custom VPC (private subnets) to default VPC
resource "aws_route" "private_to_default_peer_1" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}
# Get the default route tables for the default VPC:
data "aws_route_tables" "default_vpc_rts" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Add Routes in Default VPC to reach Custom VPC
# Create a route table if not found or update existing one
resource "aws_route" "default_to_main_peer" {
  route_table_id         = data.aws_route_tables.default_vpc_rts.ids[0]
  destination_cidr_block = aws_vpc.main_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer.id
}


