#!/bin/bash

# Script para construir imágenes Docker y enviarlas a Zot

set -e

echo "🔨 Construyendo imágenes Docker..."

# Variables
ZOT_REGISTRY_IP=${1:-"localhost:5000"}  # IP de tu VM con Zot
NAMESPACE="weather-tweets"

echo "🎯 Usando Zot en: $ZOT_REGISTRY_IP"

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Construir API Rust
echo "🦀 Construyendo API Rust..."
docker build -f proyecto3/docker/Dockerfile.rust -t weather-api:latest proyecto3/rust-api/
print_status "API Rust construida"

# Construir Go Processor
echo "🐹 Construyendo Go Processor..."
docker build -f proyecto3/docker/Dockerfile.go -t go-processor:latest proyecto3/go-processor/
print_status "Go Processor construido"

# Etiquetar para Zot
echo "🏷️  Etiquetando imágenes para Zot..."
docker tag weather-api:latest $ZOT_REGISTRY_IP/weather-api:latest
docker tag go-processor:latest $ZOT_REGISTRY_IP/go-processor:latest
print_status "Imágenes etiquetadas"

# Enviar a Zot
echo "📤 Enviando imágenes a Zot..."
docker push $ZOT_REGISTRY_IP/weather-api:latest || print_error "Error al enviar weather-api a Zot"
docker push $ZOT_REGISTRY_IP/go-processor:latest || print_error "Error al enviar go-processor a Zot"
print_status "Imágenes enviadas a Zot"

echo ""
echo "✅ ¡Construcción completada!"
echo ""
echo "Puedes ahora desplegar en Kubernetes. Ejemplo:"
echo "kubectl set image deployment/rust-api rust-api=$ZOT_REGISTRY_IP/weather-api:latest -n $NAMESPACE"
echo "kubectl set image deployment/go-processor go-processor=$ZOT_REGISTRY_IP/go-processor:latest -n $NAMESPACE"
