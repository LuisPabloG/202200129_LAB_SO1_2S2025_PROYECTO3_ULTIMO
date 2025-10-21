#!/bin/bash

# Script para configurar completamente el cluster de Kubernetes
# Ejecutar desde Cloud Shell: bash setup-cluster.sh

set -e

echo "🚀 Iniciando configuración del cluster Kubernetes..."
echo ""

# Variables
PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
ZONE="us-central1-c"

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

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Verificar que estamos en Cloud Shell
echo "📋 Verificando entorno..."
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl no está disponible"
    exit 1
fi
print_status "kubectl disponible"

# Configurar gcloud
echo ""
echo "⚙️  Configurando gcloud..."
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE
print_status "Proyecto configurado: $PROJECT_ID"

# Obtener credenciales del cluster
echo ""
echo "🔐 Obteniendo credenciales del cluster..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID
print_status "Credenciales obtenidas"

# Verificar conexión
echo ""
echo "🔍 Verificando conexión al cluster..."
if kubectl cluster-info &> /dev/null; then
    print_status "Conectado al cluster"
else
    print_error "No se puede conectar al cluster"
    exit 1
fi

# Verificar nodos
echo ""
echo "📊 Estado de nodos:"
kubectl get nodes
print_status "Nodos verificados"

# Instalar NGINX Ingress Controller
echo ""
echo "🔧 Instalando NGINX Ingress Controller..."
if kubectl get deployment -n ingress-nginx nginx-ingress-controller &> /dev/null 2>&1; then
    print_warning "NGINX Ingress Controller ya existe"
else
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    print_status "NGINX Ingress Controller instalado"
    
    # Esperar a que esté listo
    echo "⏳ Esperando que NGINX esté listo..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=300s || print_warning "Timeout esperando NGINX"
fi

# Crear Storage Class si no existe
echo ""
echo "💾 Verificando Storage Class..."
if ! kubectl get storageclass standard &> /dev/null; then
    print_warning "Storage Class standard no encontrada, creando..."
    kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
allowVolumeExpansion: true
EOF
    print_status "Storage Class creado"
else
    print_status "Storage Class standard disponible"
fi

# Crear namespace
echo ""
echo "📦 Creando namespace weather-tweets..."
kubectl create namespace weather-tweets --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespace weather-tweets creado/verificado"

# Obtener IP del Ingress (puede tardar)
echo ""
echo "⏳ Esperando IP externa para NGINX..."
for i in {1..30}; do
    INGRESS_IP=$(kubectl get ingress -n ingress-nginx -o jsonpath='{.items[0].status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$INGRESS_IP" ]; then
        print_status "IP de NGINX asignada: $INGRESS_IP"
        echo ""
        echo -e "${GREEN}📍 Guarda esta IP para Locust:${NC} $INGRESS_IP"
        break
    fi
    echo -n "."
    sleep 5
done

# Mostrar status final
echo ""
echo "📊 Status final del cluster:"
echo "=============================="
kubectl cluster-info
echo ""
kubectl get nodes
echo ""

# Mostrar espacios disponibles
echo ""
echo "💾 Recursos del cluster:"
kubectl top nodes || print_warning "No se pueden obtener recursos (normal en primera ejecución)"

echo ""
echo "✅ ¡Configuración del cluster completada exitosamente!"
echo ""
echo "📌 Próximos pasos:"
echo "1. Clona tu repositorio en Cloud Shell:"
echo "   git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO.git"
echo ""
echo "2. Navega a la carpeta del proyecto:"
echo "   cd 202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3"
echo ""
echo "3. Ejecuta el despliegue:"
echo "   bash scripts/deploy.sh"
echo ""
