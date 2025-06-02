


## Step 1: Launch EC2 and Install Terraform
1. Launch an EC2 instance.(Name:Terraform)
2. Connect to the EC2 instance via SSH.

---

## Step 2: Grant Permissions to Terraform
1. Navigate to **IAM (Identity and Access Management)**.
2. Go to **Users** → Click **Create User**.
3. Set **User Name** as `terraform`.
4. Click **Next** → **Set Permissions** → **Permission Options**.
5. Select **Attach Policies Directly** → Choose **Administrator Access**.
6. Click **Next** → **Create User**.
7. Open the **terraform user** profile.
8. Go to **Security Credentials** → **Access Key** → **Create Access Key**.
9. Select **Use Case** → **CLI**.
10. Confirm by selecting "I understand the recommendation and want to proceed".
11. Click **Next** → **Create Access Key**.
12. Download the **.csv file**.
---
## Step 3: Connect to Terraform EC2 Instance and Switch to Superuser

```sh
ssh -i <your-key.pem> ec2-user@<terraform-ec2-public-ip>
sudo -i
```

---
## Step 4: Configure AWS CLI on EC2

```sh
aws configure
```

**Provide the required values:**

- aws\_access\_key\_id = YOUR\_ACCESS\_KEY
- aws\_secret\_access\_key = YOUR\_SECRET\_KEY
- region = us-east-1
- output = table

**Verify configuration:**

```sh
aws configure list
aws sts get-caller-identity
```
---
## Step 5: Install Terraform on EC2
**Create a script:**
   ```sh
   vim terraform.sh
   ```
**Add the following content:**
   ```sh
   # Step 1: Install Required Packages
   sudo yum install -y yum-utils shadow-utils

   # Step 2: Add the HashiCorp Repository
   sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

   # Step 3: Install Terraform
   sudo yum -y install terraform
   terraform -version
   ```
**Run the script:**
   ```sh
   sh terraform.sh
   ```
---

### step-6  AWS Configuration and Credential Management


## 📌 Listing and Managing AWS Configuration Files

### 🔍 List All Files (Including Hidden Ones)
```bash
ls -la  
```

### 📂 List AWS Configuration Files
```bash
ls -la .aws/ 
```

### ✏️ Edit AWS Credentials File
```bash
vim .aws/credentials
```

### ✏️ Edit AWS Config File
```bash
vim .aws/config  
```

---

## 🗂 AWS Credentials File Example (`~/.aws/credentials`)

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

---

## 🗂 AWS Config File Example (`~/.aws/config`)

```ini
[default]
region = us-east-1
output = table
```

---

## 🚀 Quick AWS Configuration Commands

```bash
aws configure  # Set up AWS credentials interactively
aws configure list  # Display stored AWS credentials
aws sts get-caller-identity  # Verify AWS identity
```

✅ **Now your AWS CLI is set up and ready to use!**  
