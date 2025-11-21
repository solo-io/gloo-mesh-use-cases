#!/bin/bash

# Variables for the task role policies

ROLE_PREFIX='/ecs/ambient/'
TASK_ROLE_NAME=eks-ecs-task-role
TASK_POLICY_NAME=eks-ecs-task-policy

# Check if the task role exists using get-role
if aws iam get-role --role-name $TASK_ROLE_NAME > /dev/null 2>&1; 
then
    echo "$TASK_ROLE_NAME already exists."
    # Retrieve the existing role ARN
    TASK_ROLE_ARN=$(aws iam get-role --role-name $TASK_ROLE_NAME --query 'Role.Arn' --output text)
    echo "Existing task role ARN: $TASK_ROLE_ARN"
else
    echo "Creating task role..."

    # Create the task role and store the ARN
    TASK_ROLE_ARN=$(aws iam create-role  \
        --path "${ROLE_PREFIX}" \
        --role-name $TASK_ROLE_NAME \
        --assume-role-policy-document file://iam/trust-policy.json \
        --query 'Role.Arn' \
        --output text)
    
    # Wait until the role exists
    aws iam wait role-exists --role-name $TASK_ROLE_NAME
fi

# Export the TASK_ROLE_ARN
export TASK_ROLE_ARN
echo "TASK_ROLE_ARN exported: $TASK_ROLE_ARN"

# Check if the task policy exists
TASK_POLICY_ARN=$(aws iam list-policies \
    --query "Policies[?PolicyName=='$TASK_POLICY_NAME'].Arn" \
    --output text)

if [ -z "$TASK_POLICY_ARN" ]; then
    echo "Creating task policy..."

    # Create the task policy and store the ARN
    TASK_POLICY_ARN=$(aws iam create-policy \
        --path "${ROLE_PREFIX}" \
        --policy-name $TASK_POLICY_NAME \
        --policy-document file://iam/task-policy.json \
        --query 'Policy.Arn' \
        --output text)
else
    echo "Policy $TASK_POLICY_NAME already exists."
    echo "Existing task policy ARN: $TASK_POLICY_ARN"
fi

# Attach the task policy to the task role
aws iam attach-role-policy \
    --role-name $TASK_ROLE_NAME \
    --policy-arn $TASK_POLICY_ARN

echo "Task role is ready."