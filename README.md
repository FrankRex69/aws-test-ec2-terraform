# aws-test-ec2-terraform
Create resource Aws-Ec2 with Terraform and automatic deploy app node from Github

# start
type "npm run start" this include to two commands follows:
 - terraform init --var-file=variables.tfvars 
 - terraform apply --var-file=variables.tfvars -auto-approve

 # stop
type "npm run stop" this include the command follow:
 - terraform destroy --var-file=variables.tfvars -auto-approve
