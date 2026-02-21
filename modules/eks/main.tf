# EKS Control Plane Security Group
resource "aws_security_group" "control_plane" {
  name        = "${var.cluster_name}-control-plane-sg"
  description = "Security group for EKS Control Plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-control-plane-sg"
    }
  )
}

# Allow control plane to receive traffic from anywhere (public)
resource "aws_security_group_rule" "control_plane_ingress_public" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow public access to Kubernetes API"
}

# Allow control plane to communicate with itself
resource "aws_security_group_rule" "control_plane_ingress_self" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.control_plane.id
  self              = true
  description       = "Allow control plane self-communication"
}

# Allow all outbound traffic from control plane (all protocols including UDP for DNS)
resource "aws_security_group_rule" "control_plane_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.control_plane.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Worker Node Security Group
resource "aws_security_group" "node" {
  name        = "${var.cluster_name}-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-node-sg"
    }
  )
}

# Allow nodes to communicate with each other
resource "aws_security_group_rule" "node_ingress_self" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  self              = true
  description       = "Allow nodes to communicate with each other"
}

# Allow nodes to receive traffic from control plane (443 for webhooks + 1025-65535 for kubelet)
resource "aws_security_group_rule" "node_ingress_from_control_plane" {
  type              = "ingress"
  from_port         = 443
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  source_security_group_id = aws_security_group.control_plane.id
  description       = "Allow control plane to communicate with nodes (webhooks + kubelet)"

  depends_on = [aws_security_group.control_plane]
}

# Allow HTTP/HTTPS from NLB to nodes (NLBs pass client source IP, no SG of their own)
resource "aws_security_group_rule" "node_ingress_http_nlb" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTP from NLB to nodes"
}

resource "aws_security_group_rule" "node_ingress_https_nlb" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow HTTPS from NLB to nodes"
}

# Allow all outbound traffic from nodes
resource "aws_security_group_rule" "node_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.node.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# EKS Control Plane Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = var.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.control_plane.id]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_security_group_rule.control_plane_ingress_public,
    aws_security_group_rule.control_plane_ingress_self,
    aws_security_group_rule.control_plane_egress
  ]

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# OIDC Provider for IRSA (IAM Roles for Service Accounts)
# Commented out for now - will enable in Phase 4 for Load Balancer Controller & Karpenter

data "tls_certificate" "cluster" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-oidc"
    }
  )
}

# Launch Template for Worker Nodes (attaches node SG, configures storage, IMDSv2)
# Fixed name (not name_prefix) prevents a new LT version on every apply, which would
# trigger a rolling node restart via the managed node group update_config.
resource "aws_launch_template" "node" {
  name                   = "${var.cluster_name}-node"
  update_default_version = true

  vpc_security_group_ids = [aws_security_group.node.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

  monitoring {
    enabled = true
  }

  depends_on = [aws_security_group.node]
}

# Managed Node Groups (multiple pools)
resource "aws_eks_node_group" "main" {
  for_each = var.node_groups

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  version         = var.kubernetes_version
  ami_type        = each.value.ami_type

  launch_template {
    id      = aws_launch_template.node.id
    version = aws_launch_template.node.default_version
  }

  scaling_config {
    desired_size = each.value.desired_size
    max_size     = each.value.max_size
    min_size     = each.value.min_size
  }

  update_config {
    max_unavailable_percentage = 25
  }

  instance_types = [each.value.instance_type]
  capacity_type  = each.value.capacity_type

  labels = merge(
    each.value.labels,
    {
      "node-pool" = each.key
    }
  )

  dynamic "taint" {
    for_each = each.value.taints
    content {
      key    = taint.value.key
      value  = taint.value.value
      effect = taint.value.effect
    }
  }

  depends_on = [
    aws_launch_template.node,
    aws_security_group_rule.node_ingress_self,
    aws_security_group_rule.node_ingress_from_control_plane,
    aws_security_group_rule.node_egress
  ]

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-${each.key}-node-group"
    }
  )
}

# ──────────────────────────────────────────────────────────────
# EKS Addons
# ──────────────────────────────────────────────────────────────

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_versions.vpc_cni
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_versions.kube_proxy
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  addon_version               = var.addon_versions.coredns
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = var.tags
}

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "eks-pod-identity-agent"
  addon_version               = var.addon_versions.pod_identity_agent
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]

  tags = var.tags
}
