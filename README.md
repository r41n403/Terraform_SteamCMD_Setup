# Terraform_SteamCMD_Setup
Terraform files for automatic creation of VPC, Security Group, Route Tables, etc. for running a SteamCMD server. 


# Prerequisites

- AWS Account
- Access keys created
- AWS CLI installed and aws profile configured, this can be done through the aws-cli wizard with `aws configure`
- public/private key pair. This can be generated on linux with a simple `ssh-keygen` or with PuTTYgen on Windows

# Steps

1. Clone the repo, make edits to line 126 in main.tf and include own public key, in steamcmd_install.sh change line 4 from "examplepassword" to desired password 
2. Either from command line navigate to the cloned repo directory, or in Visual Studio Code go to File-> Open Folder -> Pick cloned repo directory
3. From commandline run `terraform init` or if using Visual Studio Code go to Terminal -> New Terminal then run `terraform init`
4. Run `terraform apply`
5. Login to your AWS console and make sure you can see the new instance created with the name "steamcmd_server"
6. If you want to get rid of everything run `terraform destroy`


> [!WARNING]
> Certain values are only used for example purposes. In the steamcmd_install.sh file there is a password set to "examplepassword" for the steam user. You will want to change this before running.