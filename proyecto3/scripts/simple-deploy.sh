#!/bin/bash

# Script de despliegue simplificado
set -e

export KUBECONFIG=~/.kube/config-simple
NAMESPACE="weather-system"
CD_PATH="/home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3"

echo "=== Inicio del despliegue ==="

# 1. Crear namespace
echo "1. Creando namespace..."
kubectl get namespace $NAMESPACE || kubectl create namespace $NAMESPACE

# 2. Desplegar Valkey
echo "2. Desplegando Valkey..."
kubectl apply -f "$CD_PATH/k8s/deployments/valkey.yaml"
kubectl apply -f "$CD_PATH/k8s/services/valkey-service.yaml"

# 3. Esperar a que Valkey esté listo
echo "3. Esperando a que Valkey esté listo..."
kubectl rollout status deployment/valkey -n $NAMESPACE --timeout=5m || true

# 4. Desplegar API Rust
echo "4. Desplegando API Rust..."
kubectl apply -f "$CD_PATH/k8s/deployments/weather-api-rust.yaml"
kubectl apply -f "$CD_PATH/k8s/services/weather-api-service.yaml"

# 5. Desplegar Processor Go
echo "5. Desplegando Processor Go..."
kubectl apply -f "$CD_PATH/k8s/deployments/weather-processor-go.yaml"
kubectl apply -f "$CD_PATH/k8s/services/weather-processor-service.yaml"

# 6. Desplegar Consumidores
echo "6. Desplegando Consumidores..."
kubectl apply -f "$CD_PATH/k8s/deployments/kafka-consumer.yaml"
kubectl apply -f "$CD_PATH/k8s/deployments/rabbitmq-consumer.yaml"

# 7. Desplegar Ingress
echo "7. Desplegando Ingress..."
kubectl apply -f "$CD_PATH/k8s/ingress/weather-ingress.yaml"

# 8. Mostrar estado
echo ""
echo "=== Estado final ==="
kubectl get all -n $NAMESPACE
echo ""
echo "Ingress:"
kubectl get ingress -n $NAMESPACE
