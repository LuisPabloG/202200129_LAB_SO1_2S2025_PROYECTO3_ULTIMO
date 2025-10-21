#!/bin/bash

# Script para desplegar todo el sistema en Kubernetes
# Uso: ./deploy.sh

set -e

echo "🚀 Iniciando despliegue de Weather Tweets en Kubernetes..."

# Variables
PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
ZONE="us-central1-c"
NAMESPACE="weather-tweets"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Verificar que estamos conectados al cluster
echo "📋 Verificando conexión al cluster..."
if ! kubectl cluster-info &> /dev/null; then
    print_error "No estás conectado a un cluster de Kubernetes"
    exit 1
fi
print_status "Conectado al cluster"

# Crear namespace
echo "📦 Creando namespace..."
kubectl apply -f k8s/base-deployment.yaml || print_warning "Namespace ya existe"
print_status "Namespace creado/verificado"

# Opcional: Instalar NGINX Ingress Controller si no está presente
echo "🔧 Verificando NGINX Ingress Controller..."
if ! kubectl get deployment -n ingress-nginx nginx-ingress-controller &> /dev/null; then
    print_warning "NGINX Ingress Controller no encontrado. Instalando..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    print_status "NGINX Ingress Controller instalado"
else
    print_status "NGINX Ingress Controller ya existe"
fi

# Esperar a que NGINX esté listo
echo "⏳ Esperando que NGINX esté listo..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s || print_warning "Timeout esperando NGINX"

# Desplegar Kafka y Zookeeper
echo "📨 Desplegando Kafka..."
kubectl apply -f k8s/kafka.yaml
print_status "Kafka desplegado"

# Desplegar RabbitMQ
echo "🐰 Desplegando RabbitMQ..."
kubectl apply -f k8s/rabbitmq.yaml
print_status "RabbitMQ desplegado"

# Desplegar Valkey y Grafana
echo "💾 Desplegando Valkey..."
kubectl apply -f k8s/valkey-grafana.yaml
print_status "Valkey y Grafana desplegados"

# Esperar a que los servicios estén listos
echo "⏳ Esperando que los servicios estén listos..."
sleep 15

# Desplegar aplicaciones
echo "🐳 Desplegando aplicaciones (Rust API y Go Processor)..."
kubectl apply -f k8s/base-deployment.yaml
print_status "Aplicaciones desplegadas"

# Esperar a que los pods estén listos
echo "⏳ Esperando que los pods estén en estado Ready..."
kubectl rollout status deployment/rust-api -n $NAMESPACE --timeout=300s || print_warning "Rust API tardó en iniciar"
kubectl rollout status deployment/go-processor -n $NAMESPACE --timeout=300s || print_warning "Go Processor tardó en iniciar"

print_status "Todos los pods están listos"

# Mostrar información de servicios
echo ""
echo "📊 Información de servicios:"
echo "=============================="
kubectl get svc -n $NAMESPACE

echo ""
echo "📋 Información de pods:"
echo "=============================="
kubectl get pods -n $NAMESPACE

echo ""
echo "🌐 Ingress:"
echo "=============================="
kubectl get ingress -n $NAMESPACE

# Obtener IP externa
echo ""
echo "📍 Acceso a servicios:"
echo "=============================="
INGRESS_IP=$(kubectl get ingress weather-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

if [ -z "$INGRESS_IP" ]; then
    INGRESS_IP=$(kubectl get ingress weather-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -z "$INGRESS_IP" ]; then
        print_warning "Ingress aún no tiene IP asignada. Intenta en unos segundos:"
        echo "kubectl get ingress weather-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0]}'"
    fi
fi

# Obtener IP de Grafana
GRAFANA_IP=$(kubectl get svc grafana-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
if [ -z "$GRAFANA_IP" ]; then
    GRAFANA_IP=$(kubectl get svc grafana-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
fi

if [ ! -z "$INGRESS_IP" ]; then
    echo ""
    echo -e "${GREEN}API Rust:${NC} http://$INGRESS_IP/api/health"
    echo -e "${GREEN}Go Processor:${NC} http://$INGRESS_IP/process"
fi

if [ ! -z "$GRAFANA_IP" ]; then
    echo -e "${GREEN}Grafana:${NC} http://$GRAFANA_IP:3000 (usuario: admin, contraseña: admin)"
fi

echo ""
print_status "¡Despliegue completado exitosamente!"
echo ""
echo "Próximos pasos:"
echo "1. Espera a que todos los pods estén en estado 'Running'"
echo "2. Ejecuta: kubectl port-forward -n $NAMESPACE svc/grafana-service 3000:3000"
echo "3. Accede a Grafana en http://localhost:3000"
echo "4. Ejecuta Locust: locust -f locust/locustfile.py --host=http://<INGRESS_IP>"
