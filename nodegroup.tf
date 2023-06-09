
resource "aws_iam_role" "node" {
  name               = "${local.cluster_name}-worker"
  assume_role_policy = <<POLICY
    {
        "Version":"2012-10-17",
        "Statement":[
            {
                "Effect":"Allow",
                "Principal":{
                    "Service":"ec2.amazonaws.com"
                },
                "Action":"sts:AssumeRole"
            }
        ]
    }
    POLICY
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "my-eks-cluster"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.private_subnets

  scaling_config {
    desired_size = 2
    max_size     = 4
    min_size     = 2
  }

  update_config {
    max_unavailable = 1
  }
  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly,
    aws_eks_cluster.main
  ]
  #   # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  #   # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.

}

resource "aws_security_group" "node_group_sg" {
  name        = "${local.cluster_name}_worker"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 65535
    protocol    = -1
  }
  ingress {
    from_port = 1025
    to_port   = 65535
    protocol  = "tcp"
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = -1
  }

  tags = {
    Name                                                  = "${local.cluster_name}-node-sg"
    "kubernetes.io/cluster/${local.cluster_name}-cluster" = "owned"
  }
}