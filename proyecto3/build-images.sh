#!/bin/bash

# Script para construir imágenes Docker para Proyecto 3
# Uso: ./build-images.sh

set -e

PROJECT_PATH="./proyecto3"
DOCKER_REGISTRY="localhost:5000"  # Para Zot registry local

echo "=========================================="
echo "Construyendo imágenes Docker - Proyecto 3"
echo "=========================================="

# 1. Construir API Rust
echo ""
echo "[1/2] Construyendo imagen Rust API..."
cd "$PROJECT_PATH/rust-api"

if ! command -v cargo &> /dev/null; then
    echo "⚠️  Rust no está instalado. Instalando..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source $HOME/.cargo/env
fi

cargo build --release
docker build -t weather-api:latest .
docker tag weather-api:latest $DOCKER_REGISTRY/weather-api:latest

echo "✓ Imagen Rust API construida"
cd ../..

# 2. Construir Go Client
echo ""
echo "[2/2] Construyendo imagen Go Client..."
cd "$PROJECT_PATH/go-deployment-1"

if ! command -v go &> /dev/null; then
    echo "⚠️  Go no está instalado. Por favor instala Go 1.21+"
    exit 1
fi

go mod download
docker build -t weather-go-client:latest .
docker tag weather-go-client:latest $DOCKER_REGISTRY/weather-go-client:latest

echo "✓ Imagen Go Client construida"
cd ../..

echo ""
echo "=========================================="
echo "✓ Todas las imágenes construidas exitosamente"
echo "=========================================="
echo ""
echo "Imágenes disponibles:"
docker images | grep -E "weather-api|weather-go-client|REPOSITORY"
