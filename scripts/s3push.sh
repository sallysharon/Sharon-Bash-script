aws s3 cp --region=eu-west-1 cicd-bootstrap.sh s3://eks-dtap-shared/cicdscripts/
aws s3api put-object-acl --bucket eks-dtap-shared --key cicdscripts/cicd-bootstrap.sh --acl public-read