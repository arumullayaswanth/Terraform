# 🚀 EKS Cluster Deployment using Terraform (Step-by-Step Guide)

This guide will help you deploy an Amazon EKS Cluster using Terraform in a structured and modular way.

---

## 📆 Folder Structure

```
eks-terraform/
│
├── provider.tf
├── variables.tf
├── vpc.tf
├── eks-cluster.tf
├── outputs.tf
└── deployment-guide.md
```

---

## 🔧 Prerequisites

Install the following:

* **Terraform**: [https://developer.hashicorp.com/terraform/install](https://developer.hashicorp.com/terraform/install)
* **AWS CLI**: [https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
* **kubectl**: [https://kubernetes.io/docs/tasks/tools/](https://kubernetes.io/docs/tasks/tools/)

---

## 1️⃣ Set Up Your Project

### Step 1: Create a project folder

```bash
mkdir eks-terraform
cd eks-terraform
```

### Step 2: Create Terraform files

```bash
touch provider.tf variables.tf vpc.tf eks-cluster.tf outputs.tf deployment-guide.md
```

Copy your respective configuration into each file. If you don’t have the files ready, let me know and I’ll generate them for you.

---

## 2️⃣ Configure AWS CLI

```bash
aws configure
```

Provide your AWS Access Key, Secret Key, and default region (e.g., `us-east-1`).

---

## 3️⃣ Initialize Terraform

```bash
terraform init
```

> Initializes the project and downloads provider plugins.

---

## 4️⃣ Validate Your Terraform Files

```bash
terraform validate
```

> Ensures your code is syntactically correct.

---

## 5️⃣ Plan Infrastructure

```bash
terraform plan
```

> Previews what will be created.

---

## 6️⃣ Apply Terraform Configuration

```bash
terraform apply
```

When prompted, confirm with:

```
yes
```

> This will create:
>
> * VPC, Subnets, IGW
> * IAM Roles for EKS
> * EKS Control Plane
> * Node Group with EC2 workers

---

## 7️⃣ Update kubeconfig to Connect to EKS

```bash
aws eks update-kubeconfig --region us-east-1 --name project-eks
```

Test the connection:

```bash
kubectl get nodes
```

You should see 2 nodes if configured as such.

---

## 8️⃣ View Terraform Outputs (Optional)

```bash
terraform output
```

Displays useful resources like cluster name, subnet IDs, etc.

---

## 🔀 Optional: Destroy Everything

If you want to clean up:

```bash
terraform destroy
```

Type `yes` when prompted.

---

## ✅ Done!

Your EKS Cluster is up and running. You can now:

* Deploy applications to Kubernetes
* Set up Helm charts
* Configure monitoring and autoscaling

---

## 🛠 Troubleshooting

* Ensure your IAM user has EKS, EC2, VPC, and IAM permissions.
* Run `terraform fmt` to auto-format files.
* Check AWS Console if resources take too long.

---
