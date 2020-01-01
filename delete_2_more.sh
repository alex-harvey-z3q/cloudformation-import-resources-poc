#!/usr/bin/env bash

sg1=sg-06678b4835e579c23
sg2=sg-016d129e1a8d1b22f

aws ec2 delete-security-group --group-id "$sg1"
aws ec2 delete-security-group --group-id "$sg2"
