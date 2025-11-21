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
fi

# Create istiod-ecs role
if aws iam get-role --role-name istiod-ecs > /dev/null 2>&1; then
    echo "Role 'istiod-ecs' already exists. Skipping creation."
else
    echo "Creating IAM role 'istiod-ecs'..."
    cat >istiod-ecs.json << EOF
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

    aws iam create-role --role-name istiod-ecs --assume-role-policy-document file://istiod-ecs.json
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create istiod-ecs role."
        exit 1
    fi
    
    rm istiod-ecs.json
    echo "Successfully created istiod-ecs role."
fi

# Create ecs-read-only policy
ECS_READ_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT}:policy/ecs-read-only"
if aws iam get-policy --policy-arn $ECS_READ_POLICY_ARN > /dev/null 2>&1; then
    echo "Policy 'ecs-read-only' already exists. Skipping creation."
else
    echo "Creating IAM policy 'ecs-read-only'..."
    cat >ecs-read-only.json << EOF
{
   "Version": "2012-10-17",
   "Statement": [
      {
            "Effect": "Allow",
            "Action": [
               "ecs:DescribeClusters",
               "ecs:ListClusters",
               "ecs:DescribeServices",
               "ecs:ListServices",
               "ecs:DescribeTasks",
               "ecs:ListTasks"
            ],
            "Resource": "*"
      }
   ]
}
EOF

    aws iam create-policy --policy-name ecs-read-only --policy-document file://ecs-read-only.json
    
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create ecs-read-only policy."
        exit 1
    fi
    
    rm ecs-read-only.json
    echo "Successfully created ecs-read-only policy."
fi

# Attach ecs-read-only policy to istiod-ecs role
echo "Attaching ecs-read-only policy to istiod-ecs role..."
aws iam attach-role-policy --role-name istiod-ecs --policy-arn $ECS_READ_POLICY_ARN > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "Successfully attached ecs-read-only policy to istiod-ecs role."
else
    # Check if already attached
    if aws iam list-attached-role-policies --role-name istiod-ecs | grep -q "ecs-read-only"; then
        echo "Policy ecs-read-only is already attached to istiod-ecs role."
    else
        echo "Error: Failed to attach ecs-read-only policy to istiod-ecs role."
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
               "arn:aws:iam::${AWS_ACCOUNT}:role/istiod-ecs"
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
echo "  - IAM Role: istiod-ecs"
echo "  - IAM Policy: ecs-read-only (attached to istiod-ecs)"
echo "  - IAM Policy: istiod-${AWS_ACCOUNT} (attached to istiod)"

