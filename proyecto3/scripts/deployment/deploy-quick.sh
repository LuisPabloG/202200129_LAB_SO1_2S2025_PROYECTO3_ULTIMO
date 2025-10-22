#!/bin/bash

# Script rápido para desplegar versión de prueba en GKE sin Zot
# Usa imágenes públicas como placeholders mientras compilamos

set -e

if [ -z "$KUBECONFIG" ]; then
    export KUBECONFIG=~/.kube/config-sopes1
fi

echo "=========================================="
echo "Despliegue Rápido - FASE 1 (Sin Zot)"
echo "=========================================="

# Crear namespaces
echo ""
echo "[1/4] Creando namespaces..."
kubectl apply -f kubernetes/00-namespaces.yaml
sleep 2

# Desplegar Rust API con imagen placeholder
echo ""
echo "[2/4] Desplegando Rust API..."
kubectl apply -f kubernetes/01-rust-api-deployment.yaml
echo "✓ Rust API desplegada"

# Desplegar Go Deployment 1 con imagen placeholder
echo ""
echo "[3/4] Desplegando Go Deployment 1..."
kubectl apply -f kubernetes/02-go-deployment-1.yaml
echo "✓ Go Deployment 1 desplegado"

# Desplegar Ingress
echo ""
echo "[4/4] Desplegando Ingress..."
kubectl apply -f kubernetes/03-ingress.yaml
echo "✓ Ingress desplegado"

# Esperar pods
echo ""
echo "Esperando a que los pods estén listos (esto puede tomar 2-3 minutos)..."
echo ""

# Esperar con timeout
timeout 5m kubectl rollout status deployment/rust-api -n weather-system || echo "⚠️  Timeout esperando rust-api"
timeout 5m kubectl rollout status deployment/go-deployment-1 -n weather-system || echo "⚠️  Timeout esperando go-deployment-1"

# Mostrar estado
echo ""
echo "=========================================="
echo "Estado del despliegue:"
echo "=========================================="

kubectl get pods -n weather-system -o wide

echo ""
kubectl get svc -n weather-system

echo ""
INGRESS=$(kubectl get ingress -n weather-system weather-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

if [ -z "$INGRESS" ]; then
    echo "⚠️  IP del Ingress aún PENDING. Espera 1-2 minutos y ejecuta:"
    echo "kubectl get ingress -n weather-system"
else
    echo "✓ Ingress IP: $INGRESS"
    echo ""
    echo "Prueba los endpoints:"
    echo "  curl http://$INGRESS/"
    echo "  curl http://$INGRESS/health"
fi
