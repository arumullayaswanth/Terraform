#Step 1: Install Required Packages
echo "Updating system and installing required packages..."
sudo yum install -y yum-utils shadow-utils

#Step 2: Add the HashiCorp Repository
echo "Adding HashiCorp repository..."
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

#Step 3: Install Terraform
echo "Installing Terraform..."
sudo yum -y install terraform
echo "Verifying Terraform installation..."
terraform -version

#Step 4: Configure AWS CLI
echo "Configuring AWS CLI..."
aws configure
echo "AWS configuration later, run"
aws configure list

echo "Installation and configuration complete!"
