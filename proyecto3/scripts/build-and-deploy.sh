#!/bin/bash

###############################################################################
# Script de Build y Deploy para Proyecto 3 - Weather Tweets System
# Carnet: 202200129
# Cluster: sopes1 (GKE)
###############################################################################

set -e

NAMESPACE="weather-system"
PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
CLUSTER_ZONE="us-central1-c"
DOCKER_REGISTRY="docker.io"  # Cambiar a tu registro privado (Zot)
DOCKER_USER="tu-usuario"
IMAGE_TAG="latest"

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Proyecto 3: Weather Tweets System${NC}"
echo -e "${GREEN}Carnet: 202200129${NC}"
echo -e "${GREEN}================================================${NC}"

# 1. Configurar kubectl
echo -e "${YELLOW}1. Configurando kubectl...${NC}"
gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID

# Crear kubeconfig con token
TOKEN=$(gcloud auth print-access-token)
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

echo -e "${GREEN}✓ kubectl configurado${NC}"

# 2. Crear namespace
echo -e "${YELLOW}2. Creando namespace...${NC}"
kubectl create namespace $NAMESPACE 2>/dev/null || echo "Namespace ya existe"
echo -e "${GREEN}✓ Namespace creado/verificado${NC}"

# 3. Instalar Helm si no existe
echo -e "${YELLOW}3. Verificando Helm...${NC}"
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi
echo -e "${GREEN}✓ Helm disponible${NC}"

# 4. Instalar NGINX Ingress Controller
echo -e "${YELLOW}4. Instalando NGINX Ingress Controller...${NC}"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update ingress-nginx
helm upgrade --install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi \
  --wait --timeout 5m || echo "⚠ NGINX instalación con timeout, continuando..."
echo -e "${GREEN}✓ NGINX Ingress Controller instalado${NC}"

# 5. Instalar Strimzi Kafka Operator
echo -e "${YELLOW}5. Instalando Strimzi Kafka Operator...${NC}"
helm repo add strimzi https://strimzi.io/charts 2>/dev/null || true
helm repo update strimzi
helm upgrade --install strimzi strimzi/strimzi-kafka-operator \
  --namespace weather-system \
  --set install.clusterOperator.enabled=true \
  --set install.topicOperator.enabled=true \
  --set install.userOperator.enabled=true \
  --wait --timeout 5m || echo "⚠ Strimzi instalación con timeout, continuando..."
echo -e "${GREEN}✓ Strimzi Kafka Operator instalado${NC}"

# 6. Desplegar Kafka Cluster
echo -e "${YELLOW}6. Desplegando Kafka Cluster...${NC}"
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: weather-kafka
  namespace: weather-system
spec:
  kafka:
    version: 3.6.0
    replicas: 1
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "250m"
    storage:
      type: ephemeral
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
  zookeeper:
    replicas: 1
    resources:
      requests:
        memory: "128Mi"
        cpu: "50m"
      limits:
        memory: "256Mi"
        cpu: "100m"
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

sleep 10

# Crear topic de Kafka
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: weather-tweets
  namespace: weather-system
  labels:
    strimzi.io/cluster: weather-kafka
spec:
  partitions: 3
  replicationFactor: 1
EOF

echo -e "${GREEN}✓ Kafka Cluster desplegado${NC}"

# 7. Instalar RabbitMQ
echo -e "${YELLOW}7. Instalando RabbitMQ...${NC}"
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update bitnami
helm upgrade --install rabbitmq bitnami/rabbitmq \
  --namespace weather-system \
  --set auth.username=guest \
  --set auth.password=guest \
  --set persistence.enabled=false \
  --set resources.requests.memory="128Mi" \
  --set resources.requests.cpu="50m" \
  --wait --timeout 5m || echo "⚠ RabbitMQ instalación con timeout, continuando..."
echo -e "${GREEN}✓ RabbitMQ instalado${NC}"

# 8. Desplegar componentes de la aplicación
echo -e "${YELLOW}8. Desplegando componentes de la aplicación...${NC}"

# Valkey
kubectl apply -f proyecto3/k8s/deployments/valkey.yaml
kubectl apply -f proyecto3/k8s/services/valkey-service.yaml
sleep 5

# Weather API (Rust)
kubectl apply -f proyecto3/k8s/deployments/weather-api-rust.yaml
kubectl apply -f proyecto3/k8s/services/weather-api-service.yaml
sleep 5

# Weather Processor (Go)
kubectl apply -f proyecto3/k8s/deployments/weather-processor-go.yaml
kubectl apply -f proyecto3/k8s/services/weather-processor-service.yaml
sleep 5

# Consumidores
kubectl apply -f proyecto3/k8s/deployments/kafka-consumer.yaml
kubectl apply -f proyecto3/k8s/deployments/rabbitmq-consumer.yaml
sleep 5

# Ingress
kubectl apply -f proyecto3/k8s/ingress/weather-ingress.yaml

# HPA
kubectl apply -f proyecto3/k8s/hpa/hpa-rust.yaml

echo -e "${GREEN}✓ Componentes desplegados${NC}"

# 9. Instalar Grafana
echo -e "${YELLOW}9. Instalando Grafana...${NC}"
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update grafana
helm upgrade --install grafana grafana/grafana \
  --namespace weather-system \
  --set adminPassword=admin \
  --set persistence.enabled=false \
  --set resources.requests.memory="128Mi" \
  --set resources.requests.cpu="50m" \
  --wait --timeout 5m || echo "⚠ Grafana instalación con timeout, continuando..."
echo -e "${GREEN}✓ Grafana instalado${NC}"

# 10. Mostrar status
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}Despliegue completado!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

echo "Estado del cluster:"
kubectl get all -n $NAMESPACE
echo ""

echo "Ingress:"
kubectl get ingress -n $NAMESPACE
echo ""

echo "Para acceder a Grafana:"
echo "  kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo ""

echo "Para acceder a RabbitMQ Management:"
echo "  kubectl port-forward -n $NAMESPACE svc/rabbitmq 15672:15672"
echo ""

echo "Para ver logs de un pod:"
echo "  kubectl logs -f deployment/weather-api-rust -n $NAMESPACE"
echo ""
