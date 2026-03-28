resource "aws_vpc" "this" {
    cidr_block = "10.1.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true

    tags = { Name = "${var.app_name}-${var.env}-vpc" }
}

resource "aws_subnet" "public" {
    count = 2
    vpc_id = aws_vpc.this.id
    cidr_block = ["10.1.1.0/24", "10.1.2.0/24"][count.index]
    availability_zone = ["ap-southeast-1a", "ap-southeast-1b"][count.index]
    map_public_ip_on_launch =  true

    tags = { Name = "${var.app_name}-${var.env}-public-${count.index + 1}" }
}

resource "aws_subnet" "private" {
    count = 2
    vpc_id = aws_vpc.this.id
    cidr_block = ["10.1.10.0/24", "10.1.11.0/24"][count.index]
    availability_zone = ["ap-southeast-1a", "ap-southeast-1b"][count.index]

    tags = { Name = "${var.app_name}-${var.env}-private-${count.index + 1}" }
}

resource "aws_internet_gateway" "this" {
    vpc_id = aws_vpc.this.id
    tags = { Name = "${var.app_name}-${var.env}-igw" }
}

resource "aws_eip" "nat" {
    domain = "vpc"
    tags = { Name = "${var.app_name}-${var.env}-nat-eip" }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id
  depends_on = [aws_internet_gateway.this]
  tags = { Name = "${var.app_name}-${var.env}-nat"}
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.this.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.this.id
    }
    tags = { Name = "${var.app_name}-${var.env}-public-rt"}
}

resource "aws_route_table_association" "public" {
    count = 2
    subnet_id = aws_subnet.public[count.index].id
    route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.this.id
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.this.id
    }

    tags = { Name = "${var.app_name}-${var.env}-private-rt"}
}

resource "aws_route_table_association" "private" {
  count = 2
  subnet_id = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "alb" {
    name = "${var.app_name}-${var.env}-alb-sg"
    vpc_id = aws_vpc.this.id

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.app_name}-${var.env}-alg-sg"}
}

resource "aws_security_group" "ecs" {
    name = "${var.app_name}-${var.env}-ecs-sg"
    vpc_id = aws_vpc.this.id

    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        security_groups = [aws_security_group.alb.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.app_name}-${var.env}-ecs-sg"}
}

resource "aws_security_group" "rds" {
    name = "${var.app_name}-${var.env}-rds-sg"
    vpc_id = aws_vpc.this.id

    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        security_groups = [aws_security_group.ecs.id]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.app_name}-${var.env}-rds-sg"}
}