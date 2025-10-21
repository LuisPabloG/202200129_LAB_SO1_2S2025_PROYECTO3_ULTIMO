#!/bin/bash

# Script de instalación completa del cluster desde Cloud Shell
# Este script se ejecuta DENTRO de Cloud Shell

set -e

echo "🚀 ================================================"
echo "🚀 Configuración completa del Cluster GKE"
echo "🚀 ================================================"
echo ""

PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
ZONE="us-central1-c"
NAMESPACE="weather-tweets"

# Colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[ℹ]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════${NC}"
    echo ""
}

# STEP 1: Configurar gcloud
print_section "PASO 1: Configuración de gcloud"

gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE
print_status "Proyecto: $PROJECT_ID"
print_status "Zona: $ZONE"

# STEP 2: Obtener credenciales
print_section "PASO 2: Obtener credenciales del cluster"

gcloud container clusters get-credentials $CLUSTER_NAME \
  --zone $ZONE \
  --project $PROJECT_ID
print_status "Credenciales obtenidas para cluster: $CLUSTER_NAME"

# STEP 3: Verificar cluster
print_section "PASO 3: Verificar estado del cluster"

if kubectl cluster-info &> /dev/null; then
    print_status "Conectado al cluster"
else
    print_error "No se pudo conectar al cluster"
    exit 1
fi

# Ver nodos
echo "Nodos del cluster:"
kubectl get nodes
print_status "Cluster verificado"

# STEP 4: Crear Storage Class (si es necesario)
print_section "PASO 4: Configurar Storage Class"

if kubectl get storageclass standard &> /dev/null; then
    print_warning "Storage Class standard ya existe"
else
    print_info "Creando Storage Class standard..."
    kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
allowVolumeExpansion: true
EOF
    print_status "Storage Class standard creado"
fi

# STEP 5: Instalar NGINX Ingress Controller
print_section "PASO 5: Instalar NGINX Ingress Controller"

if kubectl get namespace ingress-nginx &> /dev/null; then
    print_warning "NGINX Ingress Controller ya existe"
else
    print_info "Instalando NGINX Ingress Controller..."
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
    
    print_info "Esperando que NGINX esté listo (máximo 5 minutos)..."
    kubectl wait --namespace ingress-nginx \
      --for=condition=ready pod \
      --selector=app.kubernetes.io/component=controller \
      --timeout=300s || print_warning "NGINX tardó en iniciar, continuando..."
    
    print_status "NGINX Ingress Controller instalado"
fi

# STEP 6: Crear namespace
print_section "PASO 6: Crear namespace para el proyecto"

kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespace '$NAMESPACE' creado/verificado"

# STEP 7: Esperar IP del Ingress
print_section "PASO 7: Obtener IP externa del NGINX Ingress"

print_info "Esperando que se asigne la IP externa (puede tardar 2-3 minutos)..."
sleep 10

for i in {1..36}; do
    INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$INGRESS_IP" ]; then
        print_status "IP del Ingress: $INGRESS_IP"
        echo ""
        echo -e "${GREEN}📍 IMPORTANTE - Guarda esta IP:${NC}"
        echo -e "${GREEN}   $INGRESS_IP${NC}"
        echo ""
        break
    fi
    echo -n "."
    sleep 5
done

# STEP 8: Mostrar status final
print_section "PASO 8: Status final del cluster"

echo "Namespaces:"
kubectl get namespaces

echo ""
echo "Nodos disponibles:"
kubectl get nodes -o wide

echo ""
echo "Pods en ingress-nginx:"
kubectl get pods -n ingress-nginx

echo ""
echo "Servicios en ingress-nginx:"
kubectl get svc -n ingress-nginx

# STEP 9: Instrucciones finales
print_section "✅ CONFIGURACIÓN COMPLETADA"

echo -e "${GREEN}Próximos pasos:${NC}"
echo ""
echo "1. Clona el repositorio (si no lo has hecho):"
echo "   git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO.git"
echo ""
echo "2. Navega a la carpeta:"
echo "   cd 202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3"
echo ""
echo "3. Ejecuta el despliegue completo:"
echo "   bash scripts/quick-deploy.sh"
echo ""
echo "Ó ejecuta los despliegues manualmente:"
echo ""
echo "   kubectl apply -f k8s/kafka.yaml"
echo "   sleep 30"
echo "   kubectl apply -f k8s/rabbitmq.yaml"
echo "   kubectl apply -f k8s/valkey-grafana.yaml"
echo "   kubectl apply -f k8s/base-deployment.yaml"
echo ""
echo -e "${YELLOW}⚠️  Nota: El cluster está listo. Solo falta desplegar los componentes de la aplicación.${NC}"
