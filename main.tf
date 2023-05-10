locals {
  cluster_name = "mycluster"
}
data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {

  source             = "terraform-aws-modules/vpc/aws"
  version            = "4.0.1"
  name               = "123-Viva-Algeria"
  cidr               = "192.168.0.0/16"
  azs                = data.aws_availability_zones.available.names[*]
  public_subnets     = ["192.168.0.0/24", "192.168.1.0/24"]
  private_subnets    = ["192.168.2.0/24", "192.168.3.0/24"]
  enable_nat_gateway = true
  tags = {

    "kubernetes.io/cluster/${local.cluster_name}" = "shared"

  }

}

resource "aws_eks_cluster" "main" {
  name     = local.cluster_name
  role_arn = aws_iam_role.cluster.arn


  vpc_config {
    subnet_ids             = module.vpc.private_subnets
    endpoint_public_access = true
    public_access_cidrs    = ["0.0.0.0/0"]
  }


  #   # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  #   # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.


}
resource "aws_iam_role" "cluster" {
  name = "${local.cluster_name}-cluster"

  assume_role_policy = <<POLICY
   {
    "Version":"2012-10-17",
    "Statement" : [
    {
     "Effect" : "Allow",
     "Principal": {
       "Service":"eks.amazonaws.com"
     
  },

    "Action" : "sts:AssumeRole"
   }
   ]
   }


 POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}


