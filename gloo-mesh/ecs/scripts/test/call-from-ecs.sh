#!/bin/bash

# Check if CLUSTER_NAME environment variable is set
if [ -z "$CLUSTER_NAME" ]; then
  echo "Error: CLUSTER_NAME environment variable is not set."
  exit 1
fi

ECS_CLUSTER_NAME="ecs-$CLUSTER_NAME"
echo "Connecting to ECS cluster: $ECS_CLUSTER_NAME"

# Automatically retrieve the Task ID
TASK_ID=$(aws ecs list-tasks \
  --cluster "$ECS_CLUSTER_NAME" \
  --service-name "shell-task" \
  --query 'taskArns[0]' \
  --output text | cut -d'/' -f3)

echo "Using Task ID: $TASK_ID"

# Check if TASK_ID is empty or null
if [ -z "$TASK_ID" ]; then
  echo "Failed to retrieve task ID. Exiting."
  exit 1
fi

# Test connectivity from ECS shell task to EKS echo service
TARGET_URL="eks-echo.default:8080"

echo "-----"
echo "Testing connectivity from ECS to EKS"
echo "Running command: curl $TARGET_URL"
echo "-----"

# Execute the curl command on the ECS task
final_cmd="sh -c 'curl $TARGET_URL'"

output=$(aws ecs execute-command \
    --cluster "$ECS_CLUSTER_NAME" \
    --task "$TASK_ID" \
    --container "shell-task" \
    --interactive \
    --command "$final_cmd" 2>&1 | grep -v "Starting session with" | grep -v "Exiting session with" | grep -v "The Session Manager plugin was installed successfully" | grep -v '^$')

# Print the output
echo "$output"
echo ""
echo "Test completed successfully."