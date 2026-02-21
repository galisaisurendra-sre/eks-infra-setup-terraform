# Production-Grade EKS Cluster Implementation Plan

This document outlines the step-by-step tasks required to build a secure, scalable, and production-ready EKS cluster.

---

## Phase 1: Networking Foundation (VPC)
The network layer provides the isolation and connectivity required for the cluster.

- [ ] **Design VPC Architecture**
    - Define VPC CIDR.
    - Select **3 Availability Zones (AZs)** for high availability.
- [ ] **Create Subnets**
    - Create **3 Public Subnets** for Load Balancers and NAT Gateways.
        - Tag: `kubernetes.io/role/elb = 1`
    - Create **3 Private Subnets** for EKS Nodes.
        - Tag: `kubernetes.io/role/internal-elb = 1`
- [ ] **Configure Connectivity**
    - Attach an Internet Gateway (IGW) to the VPC.
    - Deploy **3 NAT Gateways** (one per AZ) to ensure high availability for outbound traffic.
    - Configure Route Tables for public and private subnets.
- [ ] **Optimize Security & Cost**
    - Create VPC Endpoints (PrivateLink) for `s3`, `ecr.api`, `ecr.dkr`, `sts`, and `logs` to keep traffic internal.

## Phase 2: Security & IAM
Establish the security perimeter and identity management before provisioning compute.

- [x] **IAM Roles**
    - Create **Cluster Role**: Allow EKS control plane to manage AWS resources.
    - Create **Node Role**: Allow worker nodes to pull images and network (`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`).
- [x] **Security Groups**
    - Define Control Plane Security Group.
    - Define Worker Node Security Group.

## Phase 3: EKS Cluster Provisioning
Deploy the control plane and worker nodes.

- [x] **Deploy Control Plane**
    - Provision EKS Cluster (latest stable version).
    - Enable **Control Plane Logging** (API, Audit, Authenticator, ControllerManager, Scheduler).
    - Configure API Endpoint Access: Public & Private Access enabled.
- [x] **Identity Integration**
    - Enable **OIDC Provider** to allow IAM Roles for Service Accounts (IRSA).
- [x] **Deploy Worker Nodes**
    - Create **Managed Node Groups** (System + General).
    - Strategy: Use On-Demand instances for both pools.
    - Ensure instance types have sufficient ENI capacity (t3.medium).
- [x] **Core EKS Addons**
    - Install **VPC CNI** (`v1.21.1-eksbuild.3`) — native pod networking.
    - Install **kube-proxy** (`v1.32.11-eksbuild.2`) — node-level service routing.
    - Install **CoreDNS** (`v1.11.4-eksbuild.28`) — cluster DNS and service discovery.
    - Install **EKS Pod Identity Agent** (`v1.3.0-eksbuild.1`) — IAM role binding for pods.
