# Cloudformation test repo

Usage:

Validate:

```text
aws cloudformation validate-template --template-body file://cloudformation.yml
```

Create:

```text
aws cloudformation deploy --stack-name test-stack --template-file cloudformation.yml
```

Delete:

```text
aws cloudformation delete-stack --stack-name test-stack
```
