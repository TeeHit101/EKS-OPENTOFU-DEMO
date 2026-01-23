# AWS EKS Infrastructure with Terraform

This project creates AWS EKS (Kubernetes) infrastructure using OpenTofu.

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
    ├── start.ps1          # Automated setup script for Windows
    └── start.sh           # Automated setup script for Linux/Mac
```

## 📋 Prerequisites

- AWS CLI configured with credentials
- OpenTofu or Terraform installed
- PowerShell (for Windows users)

## 🚀 Quick Start

### Option 1: Automated Setup (Recommended)

Run the setup script that does everything automatically:

**For Windows (PowerShell):**
```powershell
.\scripts\start.ps1
```

**For Linux/Mac (Bash):**
```bash
bash scripts/start.sh
```

This script will:
1. Create S3 bucket and DynamoDB table for Terraform state
2. Create IAM roles for Terraform
3. Deploy EKS cluster in dev environment

---

## 📖 Manual Setup (Step by Step)

If you prefer to run commands manually, follow these steps:

### Step 1: Deploy Bootstrap Infrastructure

Bootstrap creates the S3 bucket and DynamoDB table for storing Terraform state.

```powershell
# Go to bootstrap folder
cd bootstrap

# Initialize Terraform
tofu init

# Format all Terraform files (optional but recommended)
tofu fmt -recursive

# Check what will be created
tofu plan

# Create the infrastructure
tofu apply
```

**What this creates:**
- S3 bucket for Terraform state files
- DynamoDB table for state locking
- IAM roles for Terraform operations

### Step 2: Deploy Dev Environment

After bootstrap is complete, deploy the dev environment:

```powershell
# Go to dev environment folder
cd ..\envs\dev

# Initialize
tofu init

# Format all Terraform files (optional but recommended)
tofu fmt -recursive

# Check what will be created
tofu plan

# Create the EKS cluster
tofu apply
```

**What this creates:**
- VPC configuration (uses existing VPC)
- EKS cluster
- Node groups (worker nodes)
- Security groups
- IAM roles for EKS

### Step 3: Verify Deployment

After deployment completes, you can see the outputs:

```powershell
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

```powershell
cd envs\dev
tofu plan
tofu apply
```

### Destroy Infrastructure

To delete everything (be careful!):

```powershell
# Delete dev environment first
cd envs\dev
tofu destroy

# Then delete bootstrap (do this last!)
cd ..\..\bootstrap
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

```powershell
cd envs\dev
tofu force-unlock <LOCK_ID>
```

Replace `<LOCK_ID>` with the ID shown in the error message.

### Role Already Exists Error

If IAM roles already exist in AWS:

```powershell
# Import the existing roles
tofu import module.eks.aws_iam_role.default_cluster <role-name>
tofu import module.eks.aws_iam_role.default_node <role-name>
```

### Bootstrap Outputs Missing

If you get "outputs is object with no attributes":

```powershell
# The bootstrap hasn't been applied yet
cd bootstrap
tofu apply
```

---

## 📞 Need Help?

- Check the error message carefully
- Run `tofu plan` to see what Terraform wants to do
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
