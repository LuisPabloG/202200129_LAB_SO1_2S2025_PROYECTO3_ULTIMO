#!/bin/bash

# Script para construir y empujar imágenes a Zot Registry
# Uso: ./push-to-zot.sh <REGISTRY_URL> [REGISTRY_USER] [REGISTRY_PASS]

set -e

if [ -z "$1" ]; then
    echo "Uso: ./push-to-zot.sh <REGISTRY_URL> [REGISTRY_USER] [REGISTRY_PASS]"
    echo ""
    echo "Ejemplo:"
    echo "  ./push-to-zot.sh localhost:5000"
    echo "  ./push-to-zot.sh 34.123.45.67:5000 usuario contraseña"
    exit 1
fi

REGISTRY_URL="$1"
REGISTRY_USER="${2:-}"
REGISTRY_PASS="${3:-}"

echo "=========================================="
echo "Empujando imágenes a Zot Registry"
echo "=========================================="
echo "Registry: $REGISTRY_URL"

# Autenticarse si se proporcionan credenciales
if [ -n "$REGISTRY_USER" ] && [ -n "$REGISTRY_PASS" ]; then
    echo ""
    echo "Autenticando con Zot Registry..."
    echo "$REGISTRY_PASS" | docker login -u "$REGISTRY_USER" --password-stdin "$REGISTRY_URL"
fi

# Imágenes a empujar
IMAGES=(
    "weather-api:latest"
    "weather-go-client:latest"
)

PROJECT_PATH="./proyecto3"

# Construir y empujar cada imagen
for image in "${IMAGES[@]}"; do
    name="${image%%:*}"
    echo ""
    echo "Procesando: $name"
    
    # Verificar que la imagen existe localmente
    if docker images | grep -q "$name"; then
        docker tag "$image" "$REGISTRY_URL/$image"
        docker push "$REGISTRY_URL/$image"
        echo "✓ $image empujada a $REGISTRY_URL"
    else
        echo "⚠️  Imagen $name no encontrada localmente. Construyendo..."
        
        case "$name" in
            "weather-api")
                cd "$PROJECT_PATH/rust-api"
                docker build -t "$name:latest" .
                docker tag "$image" "$REGISTRY_URL/$image"
                docker push "$REGISTRY_URL/$image"
                cd ../../..
                echo "✓ Imagen construida y empujada"
                ;;
            "weather-go-client")
                cd "$PROJECT_PATH/go-deployment-1"
                docker build -t "$name:latest" .
                docker tag "$image" "$REGISTRY_URL/$image"
                docker push "$REGISTRY_URL/$image"
                cd ../../..
                echo "✓ Imagen construida y empujada"
                ;;
        esac
    fi
done

echo ""
echo "=========================================="
echo "✓ Todas las imágenes empujadas a Zot"
echo "=========================================="

# Mostrar imágenes en el registry
echo ""
echo "Listando imágenes en $REGISTRY_URL:"
echo "Nota: Accede a http://$REGISTRY_URL/v2/_catalog para ver todas las imágenes"
