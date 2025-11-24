#!/bin/bash

# Check if required environment variables are defined
required_vars=("AWS_REGION" "CLUSTER_NAME")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not defined."
    exit 1
  fi
done

echo "Starting cleanup of EKS cluster..."

# Check if the cluster exists
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
    echo "Deleting EKS cluster '$CLUSTER_NAME' in region '$AWS_REGION'..."
    echo "This may take several minutes..."
    
    eksctl delete cluster --name "$CLUSTER_NAME" --region "$AWS_REGION"
    
    # Check if cluster deletion was successful
    if [ $? -ne 0 ]; then
        echo "Error: Failed to delete EKS cluster '$CLUSTER_NAME'."
        exit 1
    else
        echo "EKS cluster '$CLUSTER_NAME' and all associated resources have been deleted."
    fi
else
    echo "EKS cluster '$CLUSTER_NAME' does not exist in region '$AWS_REGION'."
    
    # Check for orphaned CloudFormation stacks
    echo "Checking for orphaned CloudFormation stacks..."
    STACK_NAME="eksctl-${CLUSTER_NAME}-cluster"
    
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" > /dev/null 2>&1; then
        echo "Found orphaned CloudFormation stack '$STACK_NAME'. Deleting..."
        aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION"
        echo "Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$AWS_REGION" 2>/dev/null || true
        echo "CloudFormation stack '$STACK_NAME' deleted."
    else
        echo "No orphaned CloudFormation stacks found."
    fi
fi

echo "EKS cluster cleanup completed successfully."

