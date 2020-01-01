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
    DeletionPolicy: Retain
    Properties:
      GroupDescription: EC2 Instance access
  SGroup2:
    Type: AWS::EC2::SecurityGroup
    DeletionPolicy: Retain
    Properties:
      GroupDescription: EC2 Instance access
  SGroup1Ingress:
    Type: AWS::EC2::SecurityGroupIngress
    DeletionPolicy: Retain
    Properties:
      GroupName: !Ref SGroup1
      IpProtocol: tcp
      ToPort: 80
      FromPort: 80
      CidrIp: 0.0.0.0/0
  SGroup2Ingress:
    Type: AWS::EC2::SecurityGroupIngress
    DeletionPolicy: Retain
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

## See also

- AWS docs, [Import Existing Resources Into a Stack](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/resource-import-existing-stack.html).
