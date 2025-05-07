resource "aws_security_group" "ssh" {
  name        = "ssh"
  description = "Allow SSH"
  vpc_id      = aws_vpc.dev_vpc.id
  ingress {
    description = "Allow port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow everything outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "aws_security_group" "web-traffic" {
  name        = "web-traffic"
  description = "Allow HTTP and HTTPS traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  # Allow inbound HTTP traffic on port 80
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound HTTPS traffic on port 443
  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "Allow everything outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "kubernetes" {
  name        = "kubernetes"
  description = "Allow Kubernetes API server, kubelet, and SSH,etcd,apiserver"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow Kubernetes API server port"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow kubelet communication"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow kubelet communication"
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow kubelet communication"
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow kubelet communication"
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow everything outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# Security Group for NAT Gateway
resource "aws_security_group" "nat_gateway_sg" {
  name        = "nat-gateway-sg"
  description = "Security group for NAT Gateway"
  vpc_id      = aws_vpc.dev_vpc.id # Replace with your actual VPC ID

  # Egress rule to allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # "-1" indicates all protocols
    cidr_blocks = ["0.0.0.0/0"] # Allow outbound traffic to anywhere
  }

  # Ingress rule to allow incoming traffic from the VPC CIDR block (if needed)
  ingress {
    description = "Allow inbound traffic from the VPC CIDR block"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # Allow all protocols
    cidr_blocks = ["10.20.0.0/16"] # Replace with your internal CIDR block
  }
}




resource "aws_security_group" "open_accessfromvpc" {
  name        = "open_access_vpc"
  description = "Security group with open access within the VPC"
  vpc_id      = aws_vpc.dev_vpc.id

  ingress {
    description = "Allow all inbound traffic within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    description = "Allow all outbound traffic within the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.20.0.0/16"]
  }
}




# Ingress rule for etcd

# Data resource for availability zones
data "aws_availability_zones" "available" {}


# Security Group for etcd
resource "aws_security_group" "etcd_sg" {
  name        = "etcd-sg" # Ensure this name does not already exist
  description = "Security group for etcd"
  vpc_id      = aws_vpc.dev_vpc.id # Replace with your actual VPC ID
}

# Security Group for etcd Egress
resource "aws_security_group" "etcd_egress" {
  name        = "etcd-sg-egress" # Updated name to avoid duplication
  description = "Egress security group for etcd"
  vpc_id      = aws_vpc.dev_vpc.id # Replace with your actual VPC ID
}

# Ingress rule for etcd
resource "aws_security_group_rule" "etcd_ingress" {
  type              = "ingress"
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
  cidr_blocks       = ["10.20.0.0/16"] # Replace with your internal CIDR block
  security_group_id = aws_security_group.etcd_sg.id
}


# Security Group for HAProxy
resource "aws_security_group" "haproxy_sg" {
  name        = "haproxy-sg"
  description = "Security group for HAProxy load balancer"
  vpc_id      = aws_vpc.dev_vpc.id # Replace with your actual VPC ID

  # Ingress rule for HTTP (port 80)
  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere, restrict as needed
  }

  # Ingress rule for HTTPS (port 443)
  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow from anywhere, restrict as needed
  }

  # Ingress rule for HAProxy health checks or internal access (e.g., stats page)
  ingress {
    description = "Allow internal access or health checks"
    from_port   = 9000 # Replace with your HAProxy stats or health check port
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"] # Replace with your internal CIDR block
  }

  # Egress rule to allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"             # "-1" indicates all protocols
    cidr_blocks = ["10.20.0.0/16"] # Allow traffic to any destination
  }
}

resource "aws_security_group" "node_port_group" {
  name        = "my_security_group"
  description = "Allow traffic on ports 30000-32767"
  vpc_id      = aws_vpc.dev_vpc.id # Replace with your VPC ID

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"            # Change to "udp" if needed
    cidr_blocks = ["10.20.0.0/16"] # Change to specific CIDR block for more security
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all outbound traffic
    cidr_blocks = ["10.20.0.0/16"]
  }

  tags = {
    Name = "node_port_Group"
  }
}

resource "aws_security_group" "nfs" {
  name        = "nfs-sg"
  description = "Allow NFS traffic"
  vpc_id      = aws_vpc.dev_vpc.id

  # Allow NFS communication (TCP/UDP on port 2049)
  ingress {
    description = "Allow NFS traffic"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Replace with your internal VPC CIDR block
  }

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow portmap (NFS) on port 111
  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "tcp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  ingress {
    from_port   = 111
    to_port     = 111
    protocol    = "udp"
    cidr_blocks = ["10.20.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
