#!/bin/bash

# Script to add pod identity association for istiod service account to an existing EKS cluster
# This allows istiod to assume the IAM role needed for ECS discovery

set -e

echo "========================================="
echo "Adding pod identity association for istiod"
echo "========================================="
echo ""

# Check required environment variables
if [ -z "$CLUSTER_NAME" ] || [ -z "$AWS_ACCOUNT" ] || [ -z "$AWS_REGION" ]; then
    echo "Error: Required environment variables are not set."
    echo "Please set CLUSTER_NAME, AWS_ACCOUNT, and AWS_REGION."
    exit 1
fi

NAMESPACE="istio-system"
SERVICE_ACCOUNT="istiod"
ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT}:role/istiod"

echo "Cluster: ${CLUSTER_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Service Account: ${SERVICE_ACCOUNT}"
echo "IAM Role: ${ROLE_ARN}"
echo ""

# Check if the pod identity association already exists
echo "Checking for existing pod identity association..."
EXISTING_ASSOCIATION=$(aws eks list-pod-identity-associations \
    --cluster-name "${CLUSTER_NAME}" \
    --region "${AWS_REGION}" \
    --query "associations[?serviceAccount=='${SERVICE_ACCOUNT}' && namespace=='${NAMESPACE}'].associationId" \
    --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_ASSOCIATION" ]; then
    echo "✓ Pod identity association already exists (ID: ${EXISTING_ASSOCIATION})"
    echo ""
    echo "Verifying configuration..."
    ASSOCIATION_DETAILS=$(aws eks describe-pod-identity-association \
        --cluster-name "${CLUSTER_NAME}" \
        --association-id "${EXISTING_ASSOCIATION}" \
        --region "${AWS_REGION}" \
        --output json)
    
    CURRENT_ROLE=$(echo "$ASSOCIATION_DETAILS" | jq -r '.association.roleArn')
    
    if [ "$CURRENT_ROLE" = "$ROLE_ARN" ]; then
        echo "✓ Pod identity association is correctly configured"
    else
        echo "⚠ Warning: Pod identity association exists but points to different role:"
        echo "  Current: ${CURRENT_ROLE}"
        echo "  Expected: ${ROLE_ARN}"
        echo ""
        echo "To update, delete the existing association and run this script again:"
        echo "  aws eks delete-pod-identity-association \\"
        echo "    --cluster-name ${CLUSTER_NAME} \\"
        echo "    --association-id ${EXISTING_ASSOCIATION} \\"
        echo "    --region ${AWS_REGION}"
    fi
else
    echo "Creating new pod identity association..."
    ASSOCIATION_ID=$(aws eks create-pod-identity-association \
        --cluster-name "${CLUSTER_NAME}" \
        --namespace "${NAMESPACE}" \
        --service-account "${SERVICE_ACCOUNT}" \
        --role-arn "${ROLE_ARN}" \
        --region "${AWS_REGION}" \
        --query 'association.associationId' \
        --output text)
    
    echo "✓ Pod identity association created successfully (ID: ${ASSOCIATION_ID})"
fi

echo ""
echo "========================================="
echo "Pod identity association setup complete!"
echo "========================================="
echo ""
echo "The ${NAMESPACE}/${SERVICE_ACCOUNT} service account can now assume the ${ROLE_ARN} role."
echo "This enables istiod to discover ECS services and tasks."

