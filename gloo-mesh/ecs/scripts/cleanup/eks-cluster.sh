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
fi

echo "EKS cluster cleanup completed successfully."

