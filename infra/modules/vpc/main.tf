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

