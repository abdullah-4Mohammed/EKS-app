//creat eks cluster for wboard app
provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "./modules/vpc"
  vpc_name = var.vpc_name
  cidr_block = var.vpc_cidr
  availability_zones = var.availability_zones
}

module "eks" {
  source = "./modules/eks"
  cluster_name = var.cluster_name
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.subnet_ids
}

module "iam" {
  source = "./modules/iam"
  cluster_name = var.cluster_name
}



////
module "eks" {
  source = "terraform-aws-modules/eks/aws"
  version = "19.15.1"
  cluster_name = "wboard-eks"
  cluster_version = "1.26"
  cluster_endpoint_public_access = true #The API server pulic. manage the cluster using kubectl from anywhere.
  //false: The API server endpoint will only be accessible from within the VPC.
  // This enhances security but requires you to be within the VPC or use a VPN/other access method to manage the cluster.//
  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  //the subnets where the EKS control plane (the management layer of Kubernetes) will be deployed.
  //The control plane runs in an account managed by AWS, and the Kubernetes API is exposed via the Amazon EKS endpoint.
  //Ensures high availability and fault tolerance for the control plane by spreading it across multiple availability zones.
  control_plane_subnet_ids = module.vpc.intra_subnets
  // Essential for internal service communication.
  cluster_addons = {
    coredns = {
      most_recent = true
    }
    //  Manages network rules on nodes to ensure communication between services. 
    // It's necessary for routing network traffic efficiently. 
    kube-proxy = {
      most_recent = true
    }
    //Manages the networking for pods, providing IP addresses to them from the VPC. 
    //It's crucial for pod networking within AWS.
    vpc-cni = {
      most_recent = true
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2_x86_64"
    instance_types = ["t2.micro"]
    //whether to attach the primary security group associated with the cluster to the node groups.
    //The primary security group is typically created by the EKS module itself if not provided.
    attach_cluster_primary_security_group = true
  }
  eks_managed_node_groups = {
    eks_node_group = {
      min_size     = 1
      max_size     = 8
      desired_size = 2
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment = "test"
  }
}