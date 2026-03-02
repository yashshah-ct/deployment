#!/bin/bash
set -e
export PROJECT_ID="${1:-$GCP_PROJECT_ID}"
export REGION="${2:-us-central1}"
if [ -z "$PROJECT_ID" ]; then
  echo "Usage: $0 PROJECT_ID [REGION]"
  exit 1
fi
gcloud config set project "$PROJECT_ID"
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable iam.googleapis.com
cd "$(dirname "$0")/../terraform"
cp terraform.tfvars.example terraform.tfvars 2>/dev/null || true
terraform init
terraform plan -out=tfplan -var="project_id=$PROJECT_ID" -var="region=$REGION" -var="jenkins_sa_email=jenkins@${PROJECT_ID}.iam.gserviceaccount.com"
terraform apply tfplan
gcloud container clusters get-credentials "$(terraform output -raw cluster_name)" --region "$REGION" --project "$PROJECT_ID"
