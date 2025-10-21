#!/bin/bash

# Script para desplegar la Fase 1 en GKE
# Uso: KUBECONFIG=~/.kube/config-sopes1 ./deploy-phase1.sh

set -e

if [ -z "$KUBECONFIG" ]; then
    export KUBECONFIG=~/.kube/config-sopes1
fi

echo "=========================================="
echo "Desplegando Fase 1 en GKE"
echo "=========================================="

# Verificar conexión
echo ""
echo "[1/5] Verificando conexión al cluster..."
kubectl cluster-info | head -1
echo "✓ Cluster conectado"

# Crear namespaces
echo ""
echo "[2/5] Creando namespaces..."
kubectl apply -f kubernetes/00-namespaces.yaml
sleep 2
echo "✓ Namespaces creados"

# Desplegar Rust API
echo ""
echo "[3/5] Desplegando Rust API..."
kubectl apply -f kubernetes/01-rust-api-deployment.yaml
echo "✓ Rust API desplegada"

# Desplegar Go Deployment 1
echo ""
echo "[4/5] Desplegando Go Deployment 1..."
kubectl apply -f kubernetes/02-go-deployment-1.yaml
echo "✓ Go Deployment 1 desplegado"

# Desplegar Ingress
echo ""
echo "[5/5] Desplegando Ingress..."
kubectl apply -f kubernetes/03-ingress.yaml
echo "✓ Ingress desplegado"

# Esperar a que los servicios estén listos
echo ""
echo "=========================================="
echo "Esperando a que los pods estén listos..."
echo "=========================================="

kubectl rollout status deployment/rust-api -n weather-system --timeout=5m
kubectl rollout status deployment/go-deployment-1 -n weather-system --timeout=5m

# Mostrar resumen
echo ""
echo "=========================================="
echo "✓ Fase 1 desplegada exitosamente"
echo "=========================================="

echo ""
echo "Pods en weather-system:"
kubectl get pods -n weather-system -o wide

echo ""
echo "Servicios:"
kubectl get svc -n weather-system

echo ""
echo "Ingress:"
kubectl get ingress -n weather-system

INGRESS_IP=$(kubectl get ingress weather-ingress -n weather-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "PENDING")

echo ""
echo "=========================================="
echo "Información de acceso:"
echo "=========================================="
echo "Ingress IP: $INGRESS_IP"
echo "API Rust: http://$INGRESS_IP/api/weather"
echo "Go Stats: http://$INGRESS_IP/stats"
echo "Health: http://$INGRESS_IP/health"
echo "=========================================="
