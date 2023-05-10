data "aws_eks_cluster" "default" {
    name= aws_eks_cluster.main.name
}

data "aws_eks_cluster_auth" "default"{
  name= aws_eks_cluster.main.name
}


provider "kubernetes"{
    host=data.aws_eks_cluster.default.endpoint 
    cluster_ca_certificate=base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    token=data.aws_eks_cluster_auth.default.token
}

provider "helm" {
    
      kubernetes{
        host=data.aws_eks_cluster.default.endpoint
        cluster_ca_certificate=base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
        token=data.aws_eks_cluster_auth.default.token
      }
      }
    
resource "helm_release" "name" {
    name="2048-game-helm"
    chart = "${path.module}/helm/game-2048"
  
}