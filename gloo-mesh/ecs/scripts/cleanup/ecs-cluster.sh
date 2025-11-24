#!/bin/bash

# Check if required environment variables are defined
required_vars=("AWS_REGION" "CLUSTER_NAME")
for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not defined."
    exit 1
  fi
done

# Loop through services and scale down to zero, then delete
services=("shell-task" "echo-service")
for service in "${services[@]}"; do
  echo "Scaling down service '$service' in cluster 'ecs-$CLUSTER_NAME' to zero..."
  aws ecs update-service --cluster ecs-$CLUSTER_NAME --service $service --desired-count 0 > /dev/null
  
  # Check if scaling was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to scale down service '$service'."
  else
    sleep 10
  
    echo "Deleting service '$service' in cluster 'ecs-$CLUSTER_NAME'..."
    aws ecs delete-service --cluster ecs-$CLUSTER_NAME --service $service > /dev/null
  
    # Check if delete was successful
    if [ $? -ne 0 ]; then
      echo "Error: Failed to delete service '$service'."
      exit 1
    fi
  fi
done

# Deregister task definitions based on environment tag
echo "Deregistering task definitions with 'environment' tag set to 'ecs-demo'..."
for task_definition in $(aws ecs list-task-definitions --query "taskDefinitionArns[]" --output text); do
  if aws ecs list-tags-for-resource --resource-arn $task_definition --output json | jq -e '.tags[] | select(.key == "environment" and .value == "ecs-demo")' > /dev/null; then
    # Just output the deregistration message, no need to display JSON
    echo "Deregistering task definition ARN: $task_definition"
    aws ecs deregister-task-definition --task-definition $task_definition > /dev/null

    # Check if deregistration was successful
    if [ $? -ne 0 ]; then
      echo "Error: Failed to deregister task definition '$task_definition'."
      exit 1
    fi
  fi
done

echo "All task definitions with environment tag 'ecs-demo' have been deregistered successfully."

# Get VPC ID for the ECS cluster
export ecs_vpc_id=$(aws eks describe-cluster \
  --name "$CLUSTER_NAME" \
  --region "$AWS_REGION" \
  --query 'cluster.resourcesVpcConfig.vpcId' \
  --output text)

# Check if ecs_vpc_id is empty
if [ -z "$ecs_vpc_id" ]; then
  echo "Error: Failed to retrieve VPC ID."
  exit 1
fi
echo "ecs_vpc_id: $ecs_vpc_id"

# Delete ECS security group if it exists in the correct VPC
echo "Checking for ECS security group 'ecs-demo-sg' in VPC '$ecs_vpc_id'..."
existing_sg=$(aws ec2 describe-security-groups \
  --filters Name=group-name,Values=ecs-demo-sg Name=vpc-id,Values=$ecs_vpc_id \
  --query "SecurityGroups[0].GroupId" \
  --output text)

if [ "$existing_sg" != "None" ]; then
  echo "Deleting security group 'ecs-demo-sg'..." in 60 seconds
  sleep 60
  aws ec2 delete-security-group --group-id $existing_sg --region "$AWS_REGION" > /dev/null

  # Check if security group deletion was successful
  if [ $? -ne 0 ]; then
    echo "Error: Failed to delete ECS security group 'ecs-demo-sg'."
    exit 1
  else
    echo "Security group 'ecs-demo-sg' has been deleted."
  fi
else
  echo "Security group 'ecs-demo-sg' does not exist in the specified VPC."
fi

# Delete ECS cluster
echo "Deleting ECS cluster 'ecs-$CLUSTER_NAME'..."
aws ecs delete-cluster --cluster ecs-$CLUSTER_NAME > /dev/null

# Check if cluster deletion was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to delete ECS cluster 'ecs-$CLUSTER_NAME'."
  exit 1
else
  echo "ECS cluster 'ecs-$CLUSTER_NAME' has been deleted."
fi

# Delete log groups
LOG_GROUP_NAME="/ecs/ecs-${CLUSTER_NAME}"
echo "Deleting log group '$LOG_GROUP_NAME'..."
aws logs delete-log-group --log-group-name "$LOG_GROUP_NAME" > /dev/null 2>&1

# Check if log group deletion was successful
if [ $? -ne 0 ]; then
  # Check if it doesn't exist
  if ! aws logs describe-log-groups --log-group-name-prefix "$LOG_GROUP_NAME" --region $AWS_REGION 2>/dev/null | grep -q "$LOG_GROUP_NAME"; then
    echo "Log group '$LOG_GROUP_NAME' does not exist."
  else
    echo "Error: Failed to delete log group '$LOG_GROUP_NAME'."
  fi
else
  echo "Log group '$LOG_GROUP_NAME' has been deleted."
fi

echo "ECS removal script is completed successfully."