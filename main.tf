# Fetch the latest available Amazon Machine Image (AMI) for Bitnami Tomcat
data "aws_ami" "app_ami" {
  most_recent = true  # Always get the latest version

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]  # Filter AMIs based on the name pattern
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]  # Ensures the AMI supports Hardware Virtual Machine (HVM)
  }

  owners = ["979382823631"]  # Bitnami's official AWS account ID
}

# Retrieve the default VPC in the AWS account
data "aws_vpc" "default" {
  default = true  # Gets the default VPC automatically created by AWS
}

# Create an EC2 instance using the latest Bitnami Tomcat AMI
resource "aws_instance" "blog" {
  ami           = data.aws_ami.app_ami.id  # Use the fetched AMI ID
  instance_type = var.instance_type  # Instance type (e.g., "t2.micro", "t3.medium", etc.)

  vpc_security_group_ids = [aws_security_group.blog.id]  # Attach the security group to control traffic

  tags = {
    Name = "HelloWorld"  # Assign a name tag for easy identification
  }
}

# Create a security group for the EC2 instance
resource "aws_security_group" "blog" {
  name        = "blog"
  description = "Allow incoming HTTP and HTTPS connections and all outbound traffic"

  vpc_id = data.aws_vpc.default.id  # Associate this security group with the default VPC
}

# Allow inbound HTTP traffic on port 80 (for web traffic)
resource "aws_security_group_rule" "blog_http_in" {
  type              = "ingress"  # Ingress = Incoming traffic
  from_port         = 80  # HTTP port
  to_port           = 80
  protocol          = "tcp"  # Transmission Control Protocol (reliable data transfer)
  cidr_blocks       = ["0.0.0.0/0"]  # Open to the entire internet (any IP address)
  security_group_id = aws_security_group.blog.id  # Apply to the "blog" security group
}

# Allow inbound HTTPS traffic on port 443 (for secure web traffic)
resource "aws_security_group_rule" "blog_https_in" {
  type              = "ingress"
  from_port         = 443  # HTTPS port
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]  # Open to everyone
  security_group_id = aws_security_group.blog.id
}

# Allow all outbound traffic from the EC2 instance (to the internet or other services)
resource "aws_security_group_rule" "blog_everything_out" {
  type              = "egress"  # Egress = Outgoing traffic
  from_port         = 0  # Allow all ports
  to_port           = 0
  protocol          = "-1"  # "-1" means "any protocol"
  cidr_blocks       = ["0.0.0.0/0"]  # Allow outgoing traffic to any destination
  security_group_id = aws_security_group.blog.id
}
