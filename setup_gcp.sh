#!/bin/bash
# Automates Google Cloud Platform setup for Vitable Health CI/CD Pipeline
set -e

PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
REPO_NAME="vitable-repo"
SERVICE_NAME="vitable-backend"

echo "============================================="
echo " Setting up GCP for Project: $PROJECT_ID"
echo "============================================="
echo ""

# 1. Enable Required APIs
echo "[1/4] Enabling required GCP APIs..."
gcloud services enable \
    artifactregistry.googleapis.com \
    run.googleapis.com \
    cloudbuild.googleapis.com \
    secretmanager.googleapis.com \
    iamcredentials.googleapis.com
echo "APIs enabled."
echo ""

# 2. Create Artifact Registry
echo "[2/4] Setting up Artifact Registry..."
if ! gcloud artifacts repositories describe $REPO_NAME --location=$REGION > /dev/null 2>&1; then
    gcloud artifacts repositories create $REPO_NAME \
        --repository-format=docker \
        --location=$REGION \
        --description="Docker repository for Vitable backend"
    echo "Artifact Registry repository '$REPO_NAME' created."
else
    echo "Artifact Registry repository '$REPO_NAME' already exists."
fi
echo ""

# 3. Create Secret for GEMINI_KEY
echo "[3/4] Configuring Secret Manager for GEMINI_KEY..."
echo -n "Enter your GEMINI_KEY value: "
read -s GEMINI_KEY
echo ""

if ! gcloud secrets describe GEMINI_KEY > /dev/null 2>&1; then
    echo -n "$GEMINI_KEY" | gcloud secrets create GEMINI_KEY \
        --data-file=- \
        --replication-policy="automatic"
    echo "Secret 'GEMINI_KEY' created."
else
    echo -n "$GEMINI_KEY" | gcloud secrets versions add GEMINI_KEY --data-file=-
    echo "New version added to existing secret 'GEMINI_KEY'."
fi
echo ""

# 4. Grant Cloud Build service account access to Secret Manager and Cloud Run
echo "[4/4] Configuring IAM Roles for Cloud Build..."
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")
CB_SA="${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com"

# Give secret accessor role
gcloud secrets add-iam-policy-binding GEMINI_KEY \
    --member="serviceAccount:${CB_SA}" \
    --role="roles/secretmanager.secretAccessor" --quiet

# Give Cloud Run Admin role
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${CB_SA}" \
    --role="roles/run.admin" --quiet

# Give Service Account User role (needed to act as the Cloud Run compute service account)
COMPUTE_SA="${PROJECT_NUMBER}-compute@developer.gserviceaccount.com"
gcloud iam service-accounts add-iam-policy-binding $COMPUTE_SA \
    --member="serviceAccount:${CB_SA}" \
    --role="roles/iam.serviceAccountUser" --quiet

echo ""
echo "============================================="
echo " Setup Complete! "
echo "============================================="
echo "IMPORTANT NEXT STEPS:"
echo "1. Connect your GitHub repository to Cloud Build via the Google Cloud Console:"
echo "   Go to: https://console.cloud.google.com/cloud-build/repositories"
echo "2. Once connected, run the following command to create the trigger:"
echo ""
echo "gcloud builds triggers create github \\"
echo "  --repo-name=VitableHealth \\"
echo "  --repo-owner=JulioCRFilho \\"
echo "  --branch-pattern=^main$ \\"
echo "  --build-config=cloudbuild.yaml \\"
echo "  --region=$REGION"
echo "============================================="
