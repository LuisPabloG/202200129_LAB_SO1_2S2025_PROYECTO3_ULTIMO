#!/bin/bash

###############################################################################
# Script para construir imágenes Docker
# Carnet: 202200129
###############################################################################

set -e

PROJECT_DIR=$(pwd)
REGISTRY="${1:-docker.io/tuusuario}"  # Cambiar por tu registry
TAG="${2:-latest}"
DOCKERFILE_DIR="proyecto3/docker"

echo "======================================"
echo "Construyendo imágenes Docker"
echo "Registry: $REGISTRY"
echo "Tag: $TAG"
echo "======================================"

# 1. Construir Rust API
echo ""
echo "1. Construyendo Weather API (Rust)..."
docker build -f "$DOCKERFILE_DIR/Dockerfile.rust" \
  -t "$REGISTRY/weather-api-rust:$TAG" \
  -t "$REGISTRY/weather-api-rust:latest" \
  .

echo "✓ Rust API construida"

# 2. Construir Go Processor
echo ""
echo "2. Construyendo Weather Processor (Go)..."
docker build -f "$DOCKERFILE_DIR/Dockerfile.go" \
  -t "$REGISTRY/weather-processor-go:$TAG" \
  -t "$REGISTRY/weather-processor-go:latest" \
  .

echo "✓ Go Processor construido"

# 3. Construir Locust
echo ""
echo "3. Construyendo Locust Load Tester..."
docker build -f "$DOCKERFILE_DIR/Dockerfile.locust" \
  -t "$REGISTRY/locust-load-test:$TAG" \
  -t "$REGISTRY/locust-load-test:latest" \
  .

echo "✓ Locust construido"

echo ""
echo "======================================"
echo "✓ Todas las imágenes construidas!"
echo "======================================"
echo ""
echo "Imágenes creadas:"
docker images | grep "$REGISTRY" || true

echo ""
echo "Para subirlas al registry:"
echo "  docker push $REGISTRY/weather-api-rust:$TAG"
echo "  docker push $REGISTRY/weather-processor-go:$TAG"
echo "  docker push $REGISTRY/locust-load-test:$TAG"
echo ""
echo "O si usas Kind/Minikube:"
echo "  kind load docker-image $REGISTRY/weather-api-rust:$TAG"
echo "  kind load docker-image $REGISTRY/weather-processor-go:$TAG"
echo "  kind load docker-image $REGISTRY/locust-load-test:$TAG"
