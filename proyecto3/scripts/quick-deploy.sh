#!/bin/bash

###############################################################################
# Script rápido para desplegar solo la aplicación sin infraestructura
# La infraestructura (Kafka, RabbitMQ, etc) se asume ya instalada
# Carnet: 202200129
###############################################################################

set -e

NAMESPACE="weather-system"
PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
CLUSTER_ZONE="us-central1-c"

echo "======================================"
echo "Proyecto 3: Weather Tweets System"
echo "Despliegue Rápido (APP ONLY)"
echo "Carnet: 202200129"
echo "======================================"

# Conectar a GKE
echo ""
echo "1. Configurando kubectl..."
TOKEN=$(gcloud auth print-access-token)

mkdir -p ~/.kube
cat > ~/.kube/config-sopes1 << 'KUBECONFIG_EOF'
apiVersion: v1
kind: Config
clusters:
- cluster:
    server: https://34.135.121.113
    insecure-skip-tls-verify: true
  name: sopes1
contexts:
- context:
    cluster: sopes1
    user: admin
  name: sopes1
current-context: sopes1
users:
- name: admin
  user:
    token: REPLACE_TOKEN
KUBECONFIG_EOF

sed -i "s|REPLACE_TOKEN|$TOKEN|g" ~/.kube/config-sopes1
export KUBECONFIG=~/.kube/config-sopes1

echo "✓ kubectl configurado"

# Crear namespace
echo ""
echo "2. Verificando namespace..."
kubectl create namespace $NAMESPACE 2>/dev/null || echo "  (ya existe)"
echo "✓ Namespace listo"

# Desplegar componentes
echo ""
echo "3. Desplegando componentes..."

echo "  - Valkey..."
kubectl apply -f proyecto3/k8s/deployments/valkey.yaml
kubectl apply -f proyecto3/k8s/services/valkey-service.yaml

echo "  - Ingress..."
kubectl apply -f proyecto3/k8s/ingress/weather-ingress.yaml

echo "  - HPA..."
kubectl apply -f proyecto3/k8s/hpa/hpa-rust.yaml

echo "✓ Componentes desplegados"

# Mostrar status
echo ""
echo "4. Estado actual:"
echo ""
kubectl get pods -n $NAMESPACE
echo ""
kubectl get services -n $NAMESPACE
echo ""
kubectl get ingress -n $NAMESPACE

echo ""
echo "======================================"
echo "Despliegue completado!"
echo "======================================"
echo ""
echo "Próximos pasos:"
echo "1. Cambiar imagePullPolicy en los deployments de:"
echo "   - imagePullPolicy: IfNotPresent"
echo "   a:"
echo "   - imagePullPolicy: Never (si usas minikube)"
echo ""
echo "2. Ver logs:"
echo "   kubectl logs -f deployment/valkey -n $NAMESPACE"
echo ""
echo "3. Port-forward a servicios:"
echo "   kubectl port-forward -n $NAMESPACE svc/valkey-service 6379:6379"
echo ""
