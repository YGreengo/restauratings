#!/bin/bash

set -e

echo "Initializing GitOps cluster..."

# Apply app of apps and wait for it
echo "Applying app of apps..."
kubectl apply -f app-of-apps.yaml
kubectl create namespace restauratings ||true
# Wait for SealedSecrets controller to be installed by ArgoCD
echo "Waiting for SealedSecrets controller..."

while ! kubectl get deployment sealed-secrets-controller -n sealed-secrets-system >/dev/null 2>&1; do
    echo "Waiting for SealedSecrets controller deployment to be created..."
    sleep 10
done
kubectl wait --for=condition=available --timeout=300s deployment/sealed-secrets-controller -n sealed-secrets-system

# Give controller time to generate new key
echo "Letting SealedSecrets generate new key..."
sleep 10

# Get the new public key
echo "Fetching new public key..."
kubeseal --fetch-cert --controller-name=sealed-secrets-controller --controller-namespace=sealed-secrets-system > sealed-secrets-public.pem
echo "Public key saved"

# Encrypt and apply app secrets
echo "Encrypting and applying app secrets..."
if [ -f "sealed-secrets/restauratings-app-secrets-plain.yaml" ]; then
    kubeseal --format=yaml --controller-name=sealed-secrets-controller --controller-namespace=sealed-secrets-system < sealed-secrets/restauratings-app-secrets-plain.yaml > sealed-secrets/sealed-restauratings-app-secrets.yaml
    kubectl apply -f sealed-secrets/sealed-restauratings-app-secrets.yaml
    echo "App secrets applied"
else
    echo "ERROR: Plain text app secrets not found!"
    echo "Create sealed-secrets/restauratings-app-secrets-plain.yaml first"
    exit 1
fi

# Encrypt and apply mongo secrets
echo "Encrypting and applying mongo secrets..."
if [ -f "sealed-secrets/restauratings-mongo-creds-plain.yaml" ]; then
    kubeseal --format=yaml --controller-name=sealed-secrets-controller --controller-namespace=sealed-secrets-system < sealed-secrets/restauratings-mongo-creds-plain.yaml > sealed-secrets/sealed-restauratings-mongo-creds.yaml
    kubectl apply -f sealed-secrets/sealed-restauratings-mongo-creds.yaml
    echo "Mongo secrets applied"
else
    echo "ERROR: Plain text mongo secrets not found!"
    echo "Create sealed-secrets/restauratings-mongo-creds-plain.yaml first"
    exit 1
fi

# Wait for secrets to be unsealed
echo "Waiting for secrets to be unsealed..."
kubectl wait --for=jsonpath='{.data}' --timeout=60s secret/restauratings-app-secrets -n restauratings || echo "Secret may need more time"
kubectl wait --for=jsonpath='{.data}' --timeout=60s secret/restauratings-mongo-creds -n restauratings || echo "Secret may need more time"

echo "Cluster initialization complete!"
echo ""
echo "Sealed secrets have been regenerated with new key"
echo ""
echo "Starting port forwarding..."
echo "ArgoCD will be available on https://localhost:8080"
echo "Grafana will be available on http://localhost:3000"
echo "Kibana will be available on http://localhost:5601"
echo "argo password is: "
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# Start port forwarding
kubectl port-forward -n monitoring svc/grafana 3000:80 &
kubectl port-forward -n logging svc/kibana 5601:5601 &

echo "All port forwards started. Press Ctrl+C to stop all."
wait