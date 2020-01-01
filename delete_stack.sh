#!/usr/bin/env bash

stack_name='test-stack'

sgs=$(aws cloudformation list-stack-resources \
  --stack-name "$stack_name" \
  --query 'StackResourceSummaries[?ResourceType==`AWS::EC2::SecurityGroup`].PhysicalResourceId' \
  --output 'text')

for sg in $sgs ; do
  sg_id=$(aws ec2 describe-security-groups \
    --query 'SecurityGroups[?GroupName==`'"$sg"'`].GroupId' --output 'text')
  aws ec2 delete-security-group --group-id "$sg_id"
done

aws cloudformation delete-stack --stack-name "$stack_name"
aws cloudformation wait stack-delete-complete --stack-name "$stack_name"
