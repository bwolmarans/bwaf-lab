# bwaf-lab

# barracuda-waf-terraform

Diagram:

![Test Image 3](https://github.com/bwolmarans/bwaf-lab/blob/master/rrrr.png)

End state:

![Test Image 4](https://github.com/bwolmarans/bwaf-lab/blob/master/resources_list.png)

Requirements:

Azure Subscription  
Azure Shell  
-Git  
-Terraform 0.12+  
-Ansible 2.9.2+  
  
Optional: PC/Mac that can run Postman  
  
Instructions:  
  
az vm image accept-terms --urn barracudanetworks:waf:hourly:latest  
git clone https://github.com/bwolmarans/bwaf-lab.git  
cd bwaf-lab  
ssh-keygen -m PEM -t rsa -b 2048 ( be careful about SSH keys don't over-write )  
terraform init  
terraform plan ( You need a unique ID for the Resource Group. Enter your first name + your phone number when asked. For example, my name is Brett and my phone number is (818) 292-7981, so I will enter brett8182925555 )  
terraform apply ( enter unique ID as above )  
Edit myazure_rm.yaml, change the string change_me to your unique ID.  
ansible-playbook -i ./myazure_rm.yml ./bwaf-playbook.yaml --limit bwaf_tf_vmbwaf*  
ansible-playbook -i ./myazure_rm.yml ./bwaf-dvwa.yaml --limit bwaf_tf_vmub* --key-file ~/.ssh/id_rsa --u azureuser  
Find your BWAF public IP in the Azure portal  
Use your web browser, browse to the BWAF, login, and verify in the BWAF GUI the WAF configuration look good  
How did you know what password to use?  
Verify that you can access the DVWA app by browsing to the Ubuntu box public IP address, port 8080, like this http://<Ubuntu public ip>:8080  
Login as user admin, password is password  
Click “Create / Reset Database”  
Click login at the very bottom of the screen  
Log back in to DVWA as user admin, password is password  
Choose SQL Injection from the left menu  
Enter 1 for the user, it will return a single user  
Perform a simple SQL Injection  
Enter for the user ' or '1'='1  
Do you get a list of all users? ( hint: yes )  
This is because this web application is Dxxx vulnerable, and is not protected.  
Now, in a new browser tab, browse to the BWAF service  
http://<bwaf public ip>:80 , login, and repeat step 1 above.  
Did the BWAF successfully block the SQL injection attack?  
Did the BWAF log the attack?  
What do you need to change to get a successful block?  







#echo yes | terraform destroy
