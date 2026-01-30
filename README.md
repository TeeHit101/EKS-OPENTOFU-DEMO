# AWS EKS Infrastructure with OpenTofu

![OpenTofu](https://img.shields.io/badge/OpenTofu-1.8+-844fba?logo=opentofu&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-EKS-FF9900?logo=amazonaws&logoColor=white)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.31-326CE5?logo=kubernetes&logoColor=white)

This project creates AWS EKS (Kubernetes) infrastructure using OpenTofu.

**📍 Default Region:** `eu-north-1` (configurable via `terraform.tfvars`)

## 📁 Project Structure

```
.
├── bootstrap/              # Creates S3 bucket and DynamoDB for state
├── envs/
│   ├── dev/               # Development environment
│   ├── stage/             # Staging environment
│   └── prod/              # Production environment
├── modules/
│   ├── eks/               # EKS cluster module
│   └── vpc/               # VPC module
└── scripts/
    └── start.ps1          # Automated setup script for Windows, Linux and Mac

```

## 📋 Prerequisites

- AWS CLI configured with credentials
- OpenTofu installed (v1.6.0 or higher)
- Command line access (PowerShell, Bash, or Zsh)

**⏱️ Estimated Total Deployment Time:** ~12-15 minutes

## 🚀 Quick Start

### Option 1: Automated Setup with CI/CD (Recommended)

This project uses a hybrid deployment approach:
- **Bootstrap**: Deployed manually using `start.ps1`
- **EKS Cluster**: Deployed via GitHub Actions CI/CD pipeline

#### Step 1: Deploy Bootstrap (Manual)

Run the setup script to deploy the bootstrap infrastructure (S3 bucket, DynamoDB table, IAM roles):

```powershell
.\scripts\start.ps1
```

When prompted:
- Select **Yes** for bootstrap deployment
- Select **No** for environment deployments (these will be handled by GitHub Actions)

**⏱️ Estimated Time:** ~2-3 minutes

#### Step 2: Deploy EKS Cluster (CI/CD)

After bootstrap completes, the GitHub Actions workflow (`.github/workflows/tofu-cd.yml`) will automatically:
1. Test AWS connection and state backend
2. Initialize OpenTofu
3. Plan the infrastructure changes
4. Apply the EKS cluster configuration

**⏱️ Estimated Time:** ~10-12 minutes

You can monitor the deployment progress in the **Actions** tab of your GitHub repository.

---

### Option 2: Fully Manual Setup

If you prefer to run all commands manually without CI/CD, see the [Manual Setup](#-manual-setup-step-by-step) section below.

---

## 📖 Manual Setup (Step by Step)

If you prefer to run commands manually, follow these steps:

### Step 1: Deploy Bootstrap Infrastructure

Bootstrap creates the S3 bucket and DynamoDB table for storing OpenTofu state.

```bash
# Go to bootstrap folder
cd bootstrap

# Initialize OpenTofu
tofu init

# Format all OpenTofu files (optional but recommended)
tofu fmt -recursive

# Check what will be created
tofu plan

# Create the infrastructure
tofu apply
```

**⏱️ Estimated Time:** ~2-3 minutes

**What this creates:**
- S3 bucket for OpenTofu state files
- DynamoDB table for state locking
- IAM roles for OpenTofu operations

### Step 2: Deploy Dev Environment

After bootstrap is complete, deploy the dev environment:

```bash
# Go to dev environment folder
cd ../envs/dev

# Initialize
tofu init

# Format all OpenTofu files (optional but recommended)
tofu fmt -recursive

# Check what will be created
tofu plan

# Create the EKS cluster
tofu apply
```

**⏱️ Estimated Time:** ~10-12 minutes

**What this creates:**
- VPC configuration (uses existing VPC)
- EKS cluster
- Node groups (worker nodes)
- Security groups
- IAM roles for EKS

### Step 3: Verify Deployment

After deployment completes, you can see the outputs:

```bash
tofu output
```

This shows:
- EKS cluster name
- EKS cluster endpoint
- IAM role ARNs

---

## 🔧 Other Commands

### Update Infrastructure

If you make changes to the code:

```bash
cd envs/dev
tofu plan
tofu apply
```

### Destroy Infrastructure

To delete everything (be careful!):

```bash
# Delete dev environment first
cd envs/dev
tofu destroy

# Then delete bootstrap (do this last!)
cd ../../bootstrap
tofu destroy
```

⚠️ **Important:** Always destroy environments BEFORE destroying bootstrap!

---

## 💡 Tips

1. **Always run `tofu plan` first** - Check what will change before applying
2. **Use the script for first setup** - `.\scripts\start.ps1` is easier
3. **Keep bootstrap separate** - Don't delete it unless you delete everything
4. **Check AWS costs** - EKS clusters cost money, remember to destroy when testing

---

## 🆘 Common Issues

### State Lock Error

If you see "Error acquiring the state lock":

```bash
cd envs/dev
tofu force-unlock <LOCK_ID>
```

Replace `<LOCK_ID>` with the ID shown in the error message.

### Role Already Exists Error

If IAM roles already exist in AWS:

```bash
# Import the existing roles
tofu import module.eks.aws_iam_role.default_cluster <role-name>
tofu import module.eks.aws_iam_role.default_node <role-name>
```

### Bootstrap Outputs Missing

If you get "outputs is object with no attributes":

```bash
# The bootstrap hasn't been applied yet
cd bootstrap
tofu apply
```

---

## 📞 Need Help?

- Check the error message carefully
- Run `tofu plan` to see what OpenTofu wants to do
- Make sure bootstrap is deployed first
- Check that AWS credentials are configured

---

## 🎯 Next Steps

After deployment:

1. Configure kubectl to access your cluster:
  ```bash
  aws eks update-kubeconfig --name <cluster-name> --region <region>
  ```

2. Verify cluster access:
  ```bash
  kubectl get nodes
  ```

3. Deploy your applications to the cluster!
