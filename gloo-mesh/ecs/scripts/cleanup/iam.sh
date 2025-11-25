#!/bin/bash

# Check if required environment variable is defined
if [ -z "$AWS_ACCOUNT" ]; then
  echo "Error: AWS_ACCOUNT is not defined."
  exit 1
fi

TASK_ROLE_NAME=eks-ecs-task-role
TASK_POLICY_NAME=eks-ecs-task-policy

echo "Starting cleanup of IAM roles and policies..."

# Get the task policy ARN
TASK_POLICY_ARN=$(aws iam list-policies \
    --query "Policies[?PolicyName=='$TASK_POLICY_NAME'].Arn" \
    --output text)

# Cleanup ECS Task Role
if aws iam get-role --role-name $TASK_ROLE_NAME > /dev/null 2>&1; then
    echo "Detaching policies from $TASK_ROLE_NAME..."
    
    # Detach task policy
    if [ ! -z "$TASK_POLICY_ARN" ]; then
        aws iam detach-role-policy \
            --role-name $TASK_ROLE_NAME \
            --policy-arn $TASK_POLICY_ARN
        echo "Detached $TASK_POLICY_NAME from $TASK_ROLE_NAME"
    fi
    
    echo "Deleting role $TASK_ROLE_NAME..."
    aws iam delete-role --role-name $TASK_ROLE_NAME
    echo "Deleted role $TASK_ROLE_NAME"
else
    echo "Task role $TASK_ROLE_NAME does not exist."
fi

# Delete ECS Task Policy
if [ ! -z "$TASK_POLICY_ARN" ]; then
    echo "Deleting policy $TASK_POLICY_NAME..."
    aws iam delete-policy --policy-arn $TASK_POLICY_ARN
    echo "Deleted policy $TASK_POLICY_NAME"
else
    echo "Task policy $TASK_POLICY_NAME does not exist."
fi

echo "ECS task IAM cleanup completed."
echo ""
echo "Starting cleanup of Istio IAM roles and policies..."

# Cleanup istiod role
if aws iam get-role --role-name istiod > /dev/null 2>&1; then
    echo "Detaching policies from istiod role..."
    
    # Detach istiod policy
    ISTIOD_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT}:policy/istiod-${AWS_ACCOUNT}"
    if aws iam get-policy --policy-arn $ISTIOD_POLICY_ARN > /dev/null 2>&1; then
        aws iam detach-role-policy \
            --role-name istiod \
            --policy-arn $ISTIOD_POLICY_ARN > /dev/null 2>&1
        echo "Detached policy istiod-${AWS_ACCOUNT} from istiod role"
        
        echo "Deleting policy istiod-${AWS_ACCOUNT}..."
        aws iam delete-policy --policy-arn $ISTIOD_POLICY_ARN
        echo "Deleted policy istiod-${AWS_ACCOUNT}"
    fi
    
    echo "Deleting istiod role..."
    aws iam delete-role --role-name istiod
    echo "Deleted istiod role"
else
    echo "istiod role does not exist."
fi

# Cleanup istiod-ecs role
if aws iam get-role --role-name istiod-ecs > /dev/null 2>&1; then
    echo "Detaching policies from istiod-ecs role..."
    
    # Detach ecs-read-only policy
    ECS_READ_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT}:policy/ecs-read-only"
    if aws iam get-policy --policy-arn $ECS_READ_POLICY_ARN > /dev/null 2>&1; then
        aws iam detach-role-policy \
            --role-name istiod-ecs \
            --policy-arn $ECS_READ_POLICY_ARN > /dev/null 2>&1
        echo "Detached policy ecs-read-only from istiod-ecs role"
        
        echo "Deleting policy ecs-read-only..."
        aws iam delete-policy --policy-arn $ECS_READ_POLICY_ARN
        echo "Deleted policy ecs-read-only"
    fi
    
    echo "Deleting istiod-ecs role..."
    aws iam delete-role --role-name istiod-ecs
    echo "Deleted istiod-ecs role"
else
    echo "istiod-ecs role does not exist."
fi

echo "Istio IAM cleanup completed."
echo ""
echo "All IAM cleanup completed successfully."