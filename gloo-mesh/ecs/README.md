# ECS integration with Istio ambient mesh

This directory contains scripts and manifests to help you integrate Amazon Elastic Container Service (ECS) workloads into an Istio ambient mesh running on Amazon Elastic Kubernetes Service (EKS).

This integration allows you to extend your Istio ambient mesh to include workloads running in Amazon ECS by leveraging a ztunnel sidecar. The ztunnel sidecar uses IAM roles to authenticate with istiod, enabling ECS workloads to communicate securely with ambient mesh services in your Kubernetes cluster over mTLS.

**Note**: ECS integration into an ambient mesh is an alpha feature in the Solo distribution of Istio version 1.28 and later, and requires an Enterprise-level license for Gloo Mesh.

## Prerequisites

Before you begin, install the following tools:
- `aws` - AWS command line tool
- `eksctl` - CLI tool for creating and managing EKS clusters
- `kubectl` - Kubernetes command line tool
- `helm` - Kubernetes package manager
- `jq` - Command-line JSON processor

You also need an Enterprise license for Gloo Mesh to use the ECS integration feature. Contact [Solo.io](https://www.solo.io/company/contact-sales/) for more information.

## Quick start

1. Clone this repository and navigate to this directory.
   ```bash
   git clone https://github.com/solo-io/gloo-mesh-use-cases.git
   cd gloo-mesh-use-cases/gloo-mesh/ecs
   ```

2. **Follow the complete guide in the [Gloo Mesh docs](https://docs.solo.io/gloo-mesh/latest/ambient/sample-apps/ecs-integration/).** The documentation provides step-by-step instructions for:
   - Setting up IAM roles and permissions
   - Creating an EKS cluster with Istio ambient mesh
   - Deploying ECS tasks and services
   - Adding ECS services to the ambient mesh
   - Testing connectivity between ECS and EKS workloads
   - Cleaning up all resources

## Directory structure

```
ecs/
├── manifests/          # Kubernetes manifests and Helm values
│   ├── eks-cluster.yaml
│   ├── eks-echo.yaml
│   ├── eks-shell.yaml
│   ├── istio-base-values.yaml
│   ├── istiod-values.yaml
│   ├── istio-cni-values.yaml
│   └── ztunnel-values.yaml
├── scripts/
│   ├── build/          # Setup scripts
│   │   ├── iam-istiod.sh
│   │   ├── iam-task.sh
│   │   ├── install-istioctl.sh
│   │   ├── istio-ambient.sh
│   │   └── ecs-tasks.sh
│   ├── cleanup/        # Cleanup scripts
│   │   ├── ecs-cluster.sh
│   │   ├── iam.sh
│   │   └── eks-cluster.sh
│   └── test/           # Testing scripts
│       └── call-from-ecs.sh
├── task_definitions/   # ECS task definitions
│   ├── shell-task.json
│   └── echo-task.json
└── iam/                # IAM policy documents
    ├── trust-policy.json
    └── task-policy.json
```