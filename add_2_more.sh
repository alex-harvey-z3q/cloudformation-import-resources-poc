#!/usr/bin/env bash

vpc_id=$(aws ec2 describe-vpcs --query \
  'Vpcs[?IsDefault==`true`].VpcId' --output 'text')

for i in 3 4 ; do
  group_name="test-group-$i"
  aws ec2 create-security-group \
    --description "Test group $i" \
    --group-name "$group_name" \
    --vpc-id "$vpc_id"
  aws ec2 authorize-security-group-ingress \
    --group-name "$group_name" \
    --protocol 'tcp' \
    --port '22' \
    --cidr '0.0.0.0/0'
done
