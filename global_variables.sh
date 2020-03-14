#!/bin/bash

export SERVICE_PROJECT_ID=$(gcloud config list --format 'value(core.project)' --quiet)

if [[ -e ${GOOGLE_APPLICATION_CREDENTIALS} ]]; then
    gcloud auth activate-service-account --key-file=${GOOGLE_APPLICATION_CREDENTIALS}

    # for general terraform
    export GOOGLE_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}
else
    echo "GCP service account key file must exist"
    exit 1
fi