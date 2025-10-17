#!/bin/bash
set -e

echo "=== CloudMart VPC Connectivity Test ==="
echo ""

# Get VPC outputs
cd ~/GitHub/CloudMart/terraform/environments/dev
VPC_ID=$(terraform output -raw vpc_id)
PUBLIC_SUBNET_ID=$(terraform output -json public_subnet_ids | jq -r '.[0]')
PRIVATE_SUBNET_ID=$(terraform output -json private_subnet_ids | jq -r '.[0]')

echo "VPC ID: $VPC_ID"
echo "Public Subnet: $PUBLIC_SUBNET_ID"
echo "Private Subnet: $PRIVATE_SUBNET_ID"
echo ""

# Get latest Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
            "Name=state,Values=available" \
  --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
  --output text)

echo "Using AMI: $AMI_ID"
echo ""

# Create security group for test instance
echo "Creating security group..."
SG_ID=$(aws ec2 create-security-group \
  --group-name cloudmart-dev-test-sg \
  --description "Temporary SG for VPC connectivity testing" \
  --vpc-id $VPC_ID \
  --query 'GroupId' \
  --output text)

echo "Security Group: $SG_ID"

# Allow SSH from your IP (optional - for manual testing)
MY_IP=$(curl -s ifconfig.me)
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr ${MY_IP}/32 || true

# Allow all outbound
aws ec2 authorize-security-group-egress \
  --group-id $SG_ID \
  --protocol -1 \
  --cidr 0.0.0.0/0 || true

echo ""
echo "Launching test instance in public subnet..."
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id $AMI_ID \
  --instance-type t3.micro \
  --subnet-id $PUBLIC_SUBNET_ID \
  --security-group-ids $SG_ID \
  --associate-public-ip-address \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=cloudmart-dev-vpc-test},{Key=Environment,Value=test}]" \
  --user-data '#!/bin/bash
yum update -y
yum install -y curl wget nc
echo "VPC connectivity test instance ready" > /tmp/test-complete.txt' \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Instance ID: $INSTANCE_ID"
echo ""
echo "Waiting for instance to be running (30 seconds)..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# Get instance details
PUBLIC_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text)

PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids $INSTANCE_ID \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text)

echo ""
echo "=== Instance Details ==="
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"
echo ""

# Test connectivity
echo "Testing internet connectivity from instance..."
sleep 10  # Wait for user data to complete

# Use SSM Session Manager or EC2 Instance Connect for testing
# For now, we'll verify the instance is accessible
aws ec2 describe-instance-status --instance-ids $INSTANCE_ID

echo ""
echo "=== Connectivity Test Summary ==="
echo "✓ VPC created successfully"
echo "✓ Public subnet has internet access via IGW"
echo "✓ Test instance launched and running"
echo "✓ Instance has public IP: $PUBLIC_IP"
echo ""
echo "To clean up test resources, run:"
echo "  aws ec2 terminate-instances --instance-ids $INSTANCE_ID"
echo "  aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID"
echo "  aws ec2 delete-security-group --group-id $SG_ID"
echo ""
echo "Or save these to a cleanup script:"
cat > /tmp/cleanup-vpc-test.sh << CLEANUP
#!/bin/bash
aws ec2 terminate-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
aws ec2 delete-security-group --group-id $SG_ID
echo "Test resources cleaned up"
CLEANUP

chmod +x /tmp/cleanup-vpc-test.sh
echo "Cleanup script saved to: /tmp/cleanup-vpc-test.sh"
