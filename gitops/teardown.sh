#!/bin/bash
set -e

echo "Tearing down cluster..."

# Check if kubectl can connect
if ! kubectl get nodes &>/dev/null; then
    echo "Cannot connect to cluster. Skipping Kubernetes cleanup."
    cd ../infrastructure
    terraform destroy -auto-approve
    exit 0
fi

# Stop port forwards
echo "Stopping port forwards..."
pkill -f "kubectl port-forward" 2>/dev/null || true

# Delete ArgoCD applications first (proper order)
echo "Removing ArgoCD applications..."
kubectl patch application app-of-apps -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
kubectl delete application app-of-apps -n argocd --timeout=300s 2>/dev/null || true

kubectl patch application ingress-nginx -n argocd -p '{"metadata":{"finalizers":null}}' --type=merge 2>/dev/null || true
kubectl delete application ingress-nginx -n argocd --timeout=300s 2>/dev/null || true

# Wait for cascading deletions
echo "Waiting for cascading deletions..."
sleep 45

# Explicitly delete ALL LoadBalancer services BEFORE namespace deletion
echo "Deleting all LoadBalancer services..."
kubectl get services --all-namespaces --field-selector spec.type=LoadBalancer -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name)"' | while read namespace name; do
    if [ ! -z "$namespace" ] && [ ! -z "$name" ]; then
        echo "  Deleting LoadBalancer service: $namespace/$name"
        kubectl delete service "$name" -n "$namespace" --timeout=300s 2>/dev/null || true
    fi
done

# Wait for AWS LoadBalancer cleanup
echo "Waiting for AWS LoadBalancer cleanup..."
sleep 60

# Now delete namespaces (gracefully, not force)
echo "Deleting namespaces..."
for ns in restauratings monitoring logging cert-manager ingress-nginx; do
    echo "  Deleting namespace: $ns"
    kubectl delete namespace "$ns" --timeout=300s 2>/dev/null || true
done

# Delete ArgoCD namespace last
echo "Deleting ArgoCD namespace..."
kubectl delete namespace argocd --timeout=300s 2>/dev/null || true

# Clean up any stuck ArgoCD namespace
kubectl get namespace argocd -o json 2>/dev/null | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/argocd/finalize" -f - 2>/dev/null || true

echo "Kubernetes teardown complete!"

# Clean up any orphaned AWS resources
echo "Checking for orphaned LoadBalancer security groups..."
VPC_ID=$(aws eks describe-cluster --name yarden-eks-cluster --query 'cluster.resourcesVpcConfig.vpcId' --output text 2>/dev/null || echo "")
if [ ! -z "$VPC_ID" ]; then
    aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$VPC_ID" --query 'SecurityGroups[?contains(GroupName, `k8s-elb`)].GroupId' --output text | tr '\t' '\n' | while read sg_id; do
        if [ ! -z "$sg_id" ]; then
            echo "  Deleting orphaned security group: $sg_id"
            aws ec2 delete-security-group --group-id "$sg_id" 2>/dev/null || true
        fi
    done
fi

# Clean up Terraform state and destroy infrastructure
echo "Destroying infrastructure..."
cd ../infrastructure

terraform state rm 'module.argocd.data.kubernetes_secret.argocd_initial_admin_secret' 2>/dev/null || true
terraform state rm 'module.argocd.kubernetes_namespace.argocd' 2>/dev/null || true
terraform state rm 'module.argocd.kubernetes_secret.repository["restauratings-gitops"]' 2>/dev/null || true
terraform state rm 'module.argocd.null_resource.install_argocd_kubectl' 2>/dev/null || true

terraform destroy -auto-approve

echo "Teardown complete!"