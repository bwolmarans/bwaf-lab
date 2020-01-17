# bwaf-lab

# barracuda-waf-terraform

End state:

![Test Image 4](https://github.com/bwolmarans/barracuda-waf-terraform/blob/master/resources_list.png)

get these files:


barracuda-playground.tf

barracuda-playbook.yaml

myzure_rm.yaml



ssh-keygen -m PEM -t rsa -b 2048

az vm image accept-terms --urn barracudanetworks:waf:hourly:latest

terraform init

terraform plan

echo yes | terraform apply

ansible-playbook -i ./myazure_rm.yml ./bwaf-playbook.yaml --limit bwaf_tf_vmbwaf*
ansible-playbook -i ./myazure_rm.yml ./bwaf-dvwa.yaml --limit bwaf_tf_vmub* --key-file .ssh/id_rsa --u azureuser


#echo yes | terraform destroy
