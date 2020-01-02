# AWS CloudFormation Import Resources Proof of Concept

## Overview

This repo documents my experiments using the new AWS CloudFormation Import Resources feature.

## Steps

### Initial template

I have a template that I found in an AWS blog post [here](https://aws.amazon.com/premiumsupport/knowledge-center/delete-cf-stack-retain-resources/):

```yaml
---
AWSTemplateFormatVersion: 2010-09-09
Description: AWS CloudFormation Import Resources demo
Resources:
  SGroup1:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: EC2 Instance access
  SGroup2:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: EC2 Instance access
  SGroup1Ingress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupName: !Ref SGroup1
      IpProtocol: tcp
      ToPort: 80
      FromPort: 80
      CidrIp: 0.0.0.0/0
  SGroup2Ingress:
    Type: AWS::EC2::SecurityGroupIngress
    Properties:
      GroupName: !Ref SGroup2
      IpProtocol: tcp
      ToPort: 80
      FromPort: 80
      CidrIp: 0.0.0.0/0
```

### Create the stack

From the CLI:

```text
▶ aws cloudformation deploy --stack-name test-stack --template-file cloudformation.yml                                                                       
Waiting for changeset to be created..
Waiting for stack create/update to complete
Successfully created/updated stack - test-stack
```

Stack status can then be viewed using e.g.

```text
▶ aws cloudformation list-stacks --query 'StackSummaries[].[StackName,StackStatus]' --output table 
----------------------------------------------------------------------------------------
|                                      ListStacks                                      |
+-------------------------------------------------------------------+------------------+                                                                                                
|  test-stack                                                       |  CREATE_COMPLETE |
+-------------------------------------------------------------------+------------------+                                                                                                
```

And created security groups can be seen using:

```text
▶ aws cloudformation list-stack-resources --stack-name test-stack \
		--query 'StackResourceSummaries[].[ResourceStatus,PhysicalResourceId]' --output table 
--------------------------------------------------------
|                  ListStackResources                  |
+------------------+-----------------------------------+
|  CREATE_COMPLETE |  test-stack-SGroup1-ZXBA8XU8RS7I  |
|  CREATE_COMPLETE |  SGroup1Ingress                   |
|  CREATE_COMPLETE |  test-stack-SGroup2-P4JAXNR04EZ0  |
|  CREATE_COMPLETE |  SGroup2Ingress                   |
+------------------+-----------------------------------+
```

### Manually create 2 more groups

Now I want to create 2 more groups that will lie outside of CloudFormation's management. Using [this](./add_2_more.sh) script I add 2 more security groups:

```bash
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
```

I run that:

```text
▶ bash -x add_2_more.sh
++ aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`true`].VpcId' --output text
+ vpc_id=xxx
+ for i in 3 4
+ group_name=test-group-3
+ aws ec2 create-security-group --description 'Test group 3' --group-name test-group-3 --vpc-id xxx
{
    "GroupId": "sg-030fb0a0675af168a"
}
+ aws ec2 authorize-security-group-ingress --group-name test-group-3 --protocol tcp --port 22 --cidr 0.0.0.0/0
+ for i in 3 4
+ group_name=test-group-4
+ aws ec2 create-security-group --description 'Test group 4' --group-name test-group-4 --vpc-id xxx
{
    "GroupId": "sg-0a830ad5218a37afd"
}
+ aws ec2 authorize-security-group-ingress --group-name test-group-4 --protocol tcp --port 22 --cidr 0.0.0.0/0
```

### Manually update the template

Modify the template to add 2 more groups. Note that I add the attribute `DeletionPolicy: Retain` to each:

```diff
diff --git a/cloudformation.yml b/cloudformation.yml
index 4b7ad0d..78e22b7 100644
--- a/cloudformation.yml
+++ b/cloudformation.yml
@@ -10,6 +10,16 @@ Resources:
     Type: AWS::EC2::SecurityGroup
     Properties:
       GroupDescription: EC2 Instance access
+  SGroup3:
+    Type: AWS::EC2::SecurityGroup
+    DeletionPolicy: Retain
+    Properties:
+      GroupDescription: EC2 Instance access
+  SGroup4:
+    Type: AWS::EC2::SecurityGroup
+    DeletionPolicy: Retain
+    Properties:
+      GroupDescription: EC2 Instance access
   SGroup1Ingress:
     Type: AWS::EC2::SecurityGroupIngress
     Properties:
```

### From the AWS Console

1. CloudFormation > Stacks > test-stack
1. Stack actions > Import resources into stack
1. Upload the above template when asked.

Note that confusingly, I had to use the GroupName when it asks for the GroupId. See also [this](https://drumcoder.co.uk/blog/2018/jul/24/security-group-not-found-vpc/) blog post.

After that the stack went to IMPORT_IN_PROGRESS and then IMPORT_COMPLETE.

### View the template in CloudFormation

I wanted to see what the new template looks like so:

```text
▶ aws cloudformation get-template --stack-name test-stack --query TemplateBody | cfn-flip -y
|
  ---
  AWSTemplateFormatVersion: 2010-09-09
  Description: AWS CloudFormation DeletionPolicy demo
  Resources:
    SGroup1:
      Type: 'AWS::EC2::SecurityGroup'
      DeletionPolicy: Retain
      Properties:
        GroupDescription: EC2 Instance access
    SGroup2:
      Type: 'AWS::EC2::SecurityGroup'
      DeletionPolicy: Retain
      Properties:
        GroupDescription: EC2 Instance access
    SGroup3:
      Type: 'AWS::EC2::SecurityGroup'
      DeletionPolicy: Retain
      Properties:
        GroupDescription: EC2 Instance access
    SGroup4:
      Type: 'AWS::EC2::SecurityGroup'
      DeletionPolicy: Retain
      Properties:
        GroupDescription: EC2 Instance access
    SGroup1Ingress:
      Type: 'AWS::EC2::SecurityGroupIngress'
      DeletionPolicy: Retain
      Properties:
        GroupName: !Ref SGroup1
        IpProtocol: tcp
        ToPort: '80'
        FromPort: '80'
        CidrIp: 0.0.0.0/0
    SGroup2Ingress:
      Type: 'AWS::EC2::SecurityGroupIngress'
      DeletionPolicy: Retain
      Properties:
        GroupName: !Ref SGroup2
        IpProtocol: tcp
        ToPort: '80'
        FromPort: '80'
        CidrIp: 0.0.0.0/0
```

## Discussion

The problem Amazon is trying to solve appears to be that in the old days, a resource that existed outside a CloudFormation stack could not be moved within CloudFormation's management without deleting and recreating the stack. Their docs [state](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import.html):

> If you created an AWS resource outside of AWS CloudFormation management, you can bring this existing resource into AWS CloudFormation management using resource import. You can manage your resources using AWS CloudFormation regardless of where they were created without having to delete and re-create them as part of a stack.

This is a different use-case from CloudFormer, which can code-generate CloudFormation templates from pre-existing AWS resources.

I had hoped that CloudFormation Import Resources could allow both, but for the moment, it doesn't help to actually generate code that could be saved in Git and revision controlled.

## See also

- AWS docs, [Import Existing Resources Into a Stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html).
