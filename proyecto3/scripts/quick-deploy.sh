#!/bin/bash

# Script rápido: Construye y despliega TODO en el cluster
# Ejecutar desde Cloud Shell después de descargar el código

set -e

PROYECTO_DIR="proyecto3"
NAMESPACE="weather-tweets"

echo "🚀 Script de despliegue rápido y completo"
echo "==========================================="
echo ""

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Verificar que estamos en el directorio correcto
if [ ! -d "$PROYECTO_DIR" ]; then
    echo "Error: Directorio $PROYECTO_DIR no encontrado"
    exit 1
fi

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl no disponible"
    exit 1
fi

print_status "Entorno verificado"

# PASO 1: Crear namespace e instalar NGINX
echo ""
echo "📦 Paso 1: Preparando cluster..."
bash $PROYECTO_DIR/scripts/setup-cluster.sh

# PASO 2: Desplegar todo
echo ""
echo "📦 Paso 2: Desplegando componentes..."
cd $PROYECTO_DIR

# Desplegar Kafka
echo "  📨 Desplegando Kafka..."
kubectl apply -f k8s/kafka.yaml
print_status "Kafka desplegado"

# Desplegar RabbitMQ
echo "  🐰 Desplegando RabbitMQ..."
kubectl apply -f k8s/rabbitmq.yaml
print_status "RabbitMQ desplegado"

# Desplegar Valkey + Grafana
echo "  💾 Desplegando Valkey + Grafana..."
kubectl apply -f k8s/valkey-grafana.yaml
print_status "Valkey + Grafana desplegados"

# Desplegar API Rust + Go + Ingress
echo "  🚀 Desplegando API Rust + Go Processor + Ingress..."
kubectl apply -f k8s/base-deployment.yaml
print_status "API y Processor desplegados"

# PASO 3: Esperar a que esté todo listo
echo ""
echo "⏳ Esperando que todos los pods estén listos..."

# Esperar a Kafka/Zookeeper
echo "  Esperando Kafka..."
kubectl rollout status deployment/kafka -n $NAMESPACE --timeout=300s || print_warning "Kafka tardó en iniciar"

# Esperar a RabbitMQ
echo "  Esperando RabbitMQ..."
kubectl rollout status deployment/rabbitmq -n $NAMESPACE --timeout=300s || print_warning "RabbitMQ tardó en iniciar"

# Esperar a Valkey
echo "  Esperando Valkey..."
kubectl rollout status deployment/valkey -n $NAMESPACE --timeout=300s || print_warning "Valkey tardó en iniciar"

# Esperar a Grafana
echo "  Esperando Grafana..."
kubectl rollout status deployment/grafana -n $NAMESPACE --timeout=300s || print_warning "Grafana tardó en iniciar"

# Esperar a Rust API
echo "  Esperando API Rust..."
kubectl rollout status deployment/rust-api -n $NAMESPACE --timeout=300s || print_warning "Rust API tardó en iniciar"

# Esperar a Go Processor
echo "  Esperando Go Processor..."
kubectl rollout status deployment/go-processor -n $NAMESPACE --timeout=300s || print_warning "Go Processor tardó en iniciar"

print_status "Todos los pods están listos"

# PASO 4: Mostrar información
echo ""
echo "📊 Estado de recursos:"
echo "===================="
echo ""
echo "Pods:"
kubectl get pods -n $NAMESPACE
echo ""
echo "Servicios:"
kubectl get svc -n $NAMESPACE
echo ""
echo "Ingress:"
kubectl get ingress -n $NAMESPACE
echo ""

# Obtener IPs
INGRESS_IP=$(kubectl get ingress weather-ingress -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
GRAFANA_IP=$(kubectl get svc grafana-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
RABBITMQ_IP=$(kubectl get svc rabbitmq-management -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)

echo ""
echo "🌐 Acceso a servicios:"
echo "===================="

if [ ! -z "$INGRESS_IP" ]; then
    echo "✓ API Rust:       http://$INGRESS_IP/api/health"
    echo "✓ Go Processor:   http://$INGRESS_IP/process"
else
    print_warning "Ingress aún no tiene IP (intenta en 1-2 minutos)"
fi

if [ ! -z "$GRAFANA_IP" ]; then
    echo "✓ Grafana:        http://$GRAFANA_IP:3000 (admin/admin)"
else
    echo "  Grafana:        kubectl port-forward svc/grafana-service 3000:3000"
fi

if [ ! -z "$RABBITMQ_IP" ]; then
    echo "✓ RabbitMQ UI:    http://$RABBITMQ_IP:15672 (guest/guest)"
else
    echo "  RabbitMQ UI:    kubectl port-forward svc/rabbitmq-management 15672:15672"
fi

# Kafka no tiene UI pública, pero puede accederse internamente
echo "  Kafka (interno): kafka-service:9092"
echo "  Valkey (interno): valkey-service:6379"

echo ""
echo "✅ ¡Despliegue completado!"
echo ""
echo "📌 Para pruebas de carga con Locust:"
echo "   locust -f ../locust/locustfile.py --host=http://$INGRESS_IP"
echo ""
