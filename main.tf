# Fetch the latest available Amazon Machine Image (AMI) for Bitnami Tomcat
data "aws_ami" "app_ami" {
  most_recent = true  # Always get the latest version

  filter {
    name = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]  # Filter AMIs based on the name pattern
  }

  filter {
    name = "virtualization-type"
    values = ["hvm"]  # Ensures the AMI supports Hardware Virtual Machine (HVM)
  }

  owners = ["979382823631"]  # Bitnami's official AWS account ID
}

# Retrieve the default VPC in the AWS account
data "aws_vpc" "default" {
  default = true  # Gets the default VPC automatically created by AWS
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# Create an EC2 instance using the latest Bitnami Tomcat AMI
resource "aws_instance" "blog" {
  ami = data.aws_ami.app_ami.id  # Use the fetched AMI ID
  instance_type = var.instance_type  # Instance type (e.g., "t2.micro", "t3.medium", etc.)

  vpc_security_group_ids = [module.blog_sg.security_group_id]  # Attach the security group to control traffic

  subnet_id = module.blog_vpc.public_subnets[0]  # Place the instance in the first public subnet
  
  tags = {
    Name = "HelloWorld"  # Assign a name tag for easy identification
  }
}

module "blog_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.3.0"
  name    = "blog_new"

  vpc_id = module.blog_vpc.vpc_id  # Use the VPC ID from the VPC module

  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  
  egress_rules       = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}
