#!/bin/bash

export SCRIPT_PATH=$(dirname "$0")

source "${SCRIPT_PATH}/../../../global_variables.sh"

export TF_INPUT_VAR_FILE="${SCRIPT_PATH}/../../../config/data-networks/vpc-network/service-project-standalone-vpc-eu-1.imok2.auto.tfvars.json"

cd ${SCRIPT_PATH}
echo "working directory ${SCRIPT_PATH}"
terraform init
terraform plan -var-file=${TF_INPUT_VAR_FILE}
terraform apply -auto-approve -var-file=${TF_INPUT_VAR_FILE}
#terraform destroy -auto-approve -var-file="../../../config/data-networks/vpc-network/service-project-standalone-vpc-eu-1.imok2.auto.tfvars.json"





