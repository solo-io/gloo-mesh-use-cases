#!/bin/bash

# Check if required environment variable is defined
if [ -z "$AWS_ACCOUNT" ]; then
  echo "Error: AWS_ACCOUNT is not defined."
  exit 1
fi

echo "Starting creation of Istiod IAM roles and policies..."

# Create istiod role
if aws iam get-role --role-name istiod > /dev/null 2>&1; then
    echo "Role 'istiod' already exists. Skipping creation."
else
    echo "Creating IAM role 'istiod'..."
    cat >istiod.json << EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
            "Effect": "Allow",
            "Principal": {
               "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
               "sts:AssumeRole",
               "sts:TagSession"
            ]
      }
   ]
}
EOF

    aws iam create-role --role-name istiod --assume-role-policy-document file://istiod.json

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create istiod role."
        exit 1
    fi

    rm istiod.json
    echo "Successfully created istiod role."

    # Wait for IAM eventual consistency
    echo "Waiting for IAM role to propagate..."
    sleep 10
fi

# Create istiod-ec2 role
if aws iam get-role --role-name istiod-ec2 > /dev/null 2>&1; then
    echo "Role 'istiod-ec2' already exists. Skipping creation."
else
    echo "Creating IAM role 'istiod-ec2'..."
    cat >istiod-ec2.json << EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
            "Effect": "Allow",
            "Principal": {
               "AWS": "arn:aws:iam::${AWS_ACCOUNT}:role/istiod"
            },
            "Action": [
               "sts:AssumeRole",
               "sts:TagSession"
            ]
      }
   ]
}
EOF

    aws iam create-role --role-name istiod-ec2 --assume-role-policy-document file://istiod-ec2.json

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create istiod-ec2 role."
        exit 1
    fi

    rm istiod-ec2.json
    echo "Successfully created istiod-ec2 role."
fi

# Create ec2-read-only policy
EC2_READ_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT}:policy/ec2-read-only"
if aws iam get-policy --policy-arn $EC2_READ_POLICY_ARN > /dev/null 2>&1; then
    echo "Policy 'ec2-read-only' already exists. Skipping creation."
else
    echo "Creating IAM policy 'ec2-read-only'..."
    cat >ec2-read-only.json << EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
            "Effect": "Allow",
            "Action": [
               "ec2:DescribeInstances",
               "ec2:DescribeTags",
               "ec2:DescribeNetworkInterfaces",
               "ec2:DescribeRegions"
            ],
            "Resource": "*"
      }
   ]
}
EOF

    aws iam create-policy --policy-name ec2-read-only --policy-document file://ec2-read-only.json

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create ec2-read-only policy."
        exit 1
    fi

    rm ec2-read-only.json
    echo "Successfully created ec2-read-only policy."
fi

# Attach ec2-read-only policy to istiod-ec2 role
echo "Attaching ec2-read-only policy to istiod-ec2 role..."
aws iam attach-role-policy --role-name istiod-ec2 --policy-arn $EC2_READ_POLICY_ARN > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Successfully attached ec2-read-only policy to istiod-ec2 role."
else
    # Check if already attached
    if aws iam list-attached-role-policies --role-name istiod-ec2 | grep -q "ec2-read-only"; then
        echo "Policy ec2-read-only is already attached to istiod-ec2 role."
    else
        echo "Error: Failed to attach ec2-read-only policy to istiod-ec2 role."
        exit 1
    fi
fi

# Create istiod-${AWS_ACCOUNT} policy
ISTIOD_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT}:policy/istiod-${AWS_ACCOUNT}"
if aws iam get-policy --policy-arn $ISTIOD_POLICY_ARN > /dev/null 2>&1; then
    echo "Policy 'istiod-${AWS_ACCOUNT}' already exists. Skipping creation."
else
    echo "Creating IAM policy 'istiod-${AWS_ACCOUNT}'..."
    cat >istiod-${AWS_ACCOUNT}.json << EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
            "Effect": "Allow",
            "Action": [
               "sts:AssumeRole",
               "sts:TagSession"
            ],
            "Resource": [
               "arn:aws:iam::${AWS_ACCOUNT}:role/istiod-ec2"
            ]
      }
   ]
}
EOF

    aws iam create-policy --policy-name istiod-${AWS_ACCOUNT} --policy-document file://istiod-${AWS_ACCOUNT}.json

    if [ $? -ne 0 ]; then
        echo "Error: Failed to create istiod-${AWS_ACCOUNT} policy."
        exit 1
    fi

    rm istiod-${AWS_ACCOUNT}.json
    echo "Successfully created istiod-${AWS_ACCOUNT} policy."
fi

# Attach istiod-${AWS_ACCOUNT} policy to istiod role
echo "Attaching istiod-${AWS_ACCOUNT} policy to istiod role..."
aws iam attach-role-policy --role-name istiod --policy-arn $ISTIOD_POLICY_ARN > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Successfully attached istiod-${AWS_ACCOUNT} policy to istiod role."
else
    # Check if already attached
    if aws iam list-attached-role-policies --role-name istiod | grep -q "istiod-${AWS_ACCOUNT}"; then
        echo "Policy istiod-${AWS_ACCOUNT} is already attached to istiod role."
    else
        echo "Error: Failed to attach istiod-${AWS_ACCOUNT} policy to istiod role."
        exit 1
    fi
fi

echo ""
echo "Istiod IAM setup completed successfully."
echo "Created resources:"
echo "  - IAM Role: istiod"
echo "  - IAM Role: istiod-ec2"
echo "  - IAM Policy: ec2-read-only (attached to istiod-ec2)"
echo "  - IAM Policy: istiod-${AWS_ACCOUNT} (attached to istiod)"
