#!/bin/bash

export SCRIPT_PATH=$(dirname "$0")

source "${SCRIPT_PATH}/../../../global_variables.sh"

cd ${SCRIPT_PATH}
echo "working directory ${SCRIPT_PATH}"
terraform init
terraform plan -var="service_project_id=${SERVICE_PROJECT_ID}"
terraform apply -auto-approve -var="service_project_id=${SERVICE_PROJECT_ID}"
#terraform destroy -auto-approve -var="service_project_id=${SERVICE_PROJECT_ID}"