# bwaf-byol-autolicense
For the SKO, some SE's won't have a BYOL BWAF instance, and the PAYG instance can't do some features, so we want all the SE's to have a BYOL BWAF.

These are the steps to use ARM templates hosted in this repo to create a resource group, and then create a BWAF BYOL instance which automatically grabs a BYOL license from a license blob.

Go to the azure portal. open the azure shell.

Accept the BYOL license with this command:

**az vm image terms accept --urn barracudanetworks:waf:byol:latest**

Create a group.  I think for the SE's, only one SE will have to do this group creation.  The others can skip to the az group deployment create command.

**az group create --name sko2020bwaf --location eastus**

Create a storage account.

**az storage account create --name sabwaf --resource-group sko2020bwaf --location eastus --sku Standard_ZRS**

In the Azure gui, after a minute so, click on the storage account, on the left menu is "keys", copy the first storage key to your buffer, so you can paste is later. 

Create a storage container.  Replace the word changeme in the command with your storage key ( the one you just copied ).  Don't worry, we're almost there now.

**az storage container create --account-name sabwaf --name contbwaf3 --auth-mode key --account-key changeme**

wget from this repo the file named barracuda-byol-license-list.json.gpg and ask Brett for the password.

**wget https://github.com/bwolmarans/bwaf-lab/blob/master/barracuda-byol-license-list.json.gpg?raw=true**

decrypt the license file using

**gpg -o barracuda-byol-license-list.json --decrypt** and use the password you got from Brett

Now upload the license file, affectionately known in Azure storage terminology as a blob, using this command:
( Put your storage account key instead of changeme )

**az storage blob upload --account-name sabwaf --container-name contbwaf3 --name barracuda-byol-license-list.json --file barracuda-byol-license-list.json --auth-mode key --account-key changeme**

Now actually create the BWAF virtual machine and everything it needs to work. It will automatically get a BYOL license from the file uploaded.  You must please change the string changeme to be your azure storage account key. Just use copy and paste to get the job done!

Unless you are the SE creating the storage account, you can just start with this command and skip the others:

**az group deployment create --parameters '{"saKey": {"value": "changeme"}}' --resource-group sko2020bwaf --template-uri https://raw.githubusercontent.com/bwolmarans/bwaf-lab/master/sko_bwaf_deployment.json**

Now go to the Azure portal, and watch the Resource Group **sko2020bwaf** get populated with vnets, vnics, subnets, and the bwaf virtual machine, and some other things too.

After 4 minutes the bwaf virtual machine should be up and running, you can login to it with the username admin and a secret password that you can either guess, or will be written on the whiteboard in the lab.

But the key is you will notice the bwaf has automatically licensed itself with a BYOL license, not a PAYG license, and that is significant because there are some important features that are only available in BYOL.

Now you can proceed to the other lab guide.

----------

# bwaf-lab #

This is the Terraform/Postman/Ansible lab.

## Diagram: ##

![Test Image 3](https://github.com/bwolmarans/bwaf-lab/blob/master/rrrr.png)

## End state: ##

![Test Image 4](https://github.com/bwolmarans/bwaf-lab/blob/master/resources_list.png)

### Requirements: ###

* Azure Subscription  
* Azure Shell containing, among other things:
** Git  
** Terraform 0.12+  
** Ansible 2.9.2+  
  
* Optional: PC/Mac that can run Postman  

### Want something running quick, without learning anything? Here's the short version ###
* az vm image terms accept --urn barracudanetworks:waf:hourly:latest  
* git clone https://github.com/bwolmarans/bwaf-lab.git  
* cd bwaf-lab  
* ssh-keygen -m PEM -t rsa -b 2048 ( be careful about existing SSH keys don't over-write )  
* terraform init
* terraform apply
* Edit myazure_rm.yaml, change the string change_me to your Azure resource group name
* ansible-playbook -i ./myazure_rm.yml ./bwaf-playbook.yaml --key-file ~/.ssh/id_rsa --u azureuser
* Find your BWAF public IP in the Azure portal  
* Web browse to your BWAF http://<bwaf public ip>:8000, login admin/Hello123456! and verify in the WAF configuration look good  
* Browse to the DVWA protected service http://<bwaf public ip>:80
  
### Full Instructions if you want to Learn Something Properly ###
* az vm image accept-terms --urn barracudanetworks:waf:hourly:latest  
* git clone https://github.com/bwolmarans/bwaf-lab.git  
* cd bwaf-lab  
* ssh-keygen -m PEM -t rsa -b 2048 ( be careful about existing SSH keys don't over-write )  
* terraform init  
* examine the terraform configuration file
* terraform plan ( You need a unique ID for the Resource Group. Enter your first name + your phone number when asked. For example, my name is Brett and my phone number is (818) 292-7981, so I will enter brett8182925555 )  
* terraform apply ( enter unique ID as above )  
* #CURL COMMANDS and SSH
* curl http://<your BWAF public IP>:8000/restapi/v3.1/login -X POST -H Content-Type:application/json -d '{"username": "admin", "password": "Hello123456!"}' 
* curl -X POST "http://<your BWAF public IP>:8000/restapi/v3.1/services " -H "accept: application/json" -u "your token:" -H "Content-Type: application/json" -d '{ "address-version": "IPv4", "app-id": "curl_app_id", "ip-address": "10.0.1.5", "name": "curl_service", "port": 80, "status": "On", "type": "HTTP"}'
* curl -X POST "http://<your BWAF public IP>:8000/restapi/v3.1/services/curl_service/servers " -H "accept: application/json" -u "your token:" -H "Content-Type: application/json" -d '{ "ip-address": "10.0.1.4", "status": "In Service", "comments": "string", "port": 8080, "address-version": "IPv4", "identifier": "IP Address", "name": "curl_server"}'
* ssh azureuser@<your ubuntu public IP>
* sudo su
* apt-get --yes --force-yes update
* apt install docker.io --yes --force-yes
* docker run -d --rm -it -p 8080:80 vulnerables/web-dvwa
* manually test. then delete server and service.
* examine the ansible playbook
* Edit myazure_rm.yaml, change the string change_me to your Azure resource group name  
* ansible-playbook -i ./myazure_rm.yml ./bwaf-playbook.yaml --key-file ~/.ssh/id_rsa --u azureuser
* Find your BWAF public IP in the Azure portal  
* Use your web browser, browse to the BWAF, login, and verify in the BWAF GUI the WAF configuration look good  
* How did you know what password to use?  
* Verify access to the DVWA app by browsing to the Ubuntu public IP, port 8080, i.e. http://<Ubuntu public ip>:8080  
* Login as user admin, password is password  
* Click “Create / Reset Database”  
* Click login at the very bottom of the screen  
* Log back in to DVWA as user admin, password is password  
* Choose SQL Injection from the left menu  
* Enter 1 for the user, it will return a single user  
* Perform a simple SQL Injection  
* Enter for the user ' or '1'='1  
* Do you get a list of all users? ( hint: yes )  
* This is because this web application is Dxxx vulnerable, and is not protected.  
* Now, in a new browser tab, browse to the BWAF service http://<bwaf public ip>:80 , login, and repeat step 1 above.  
* Did the BWAF successfully block the SQL injection attack?  
* Did the BWAF log the attack?  
* What do you need to change to get a successful block?  
* terraform destroy  
