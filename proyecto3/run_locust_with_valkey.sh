#!/bin/bash

# Script para hacer port-forward de Valkey y ejecutar Locust

echo "🔧 Iniciando port-forward de Valkey..."

# Hacer port-forward en background
kubectl port-forward -n weather-system svc/valkey 6379:6379 &
PF_PID=$!

echo "✓ Port-forward iniciado (PID: $PF_PID)"
echo "⏳ Esperando 3 segundos..."
sleep 3

# Navegar al directorio correcto
cd /home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3

echo "🚀 Iniciando Locust..."

# Ejecutar Locust
docker run --rm -p 8093:8089 \
  -v $(pwd):/app \
  --network host \
  python:3.11-slim bash -c "cd /app && pip install -q -r locust/requirements.txt && locust -f locust/locustfile.py -H http://34.70.218.90 --web-host=0.0.0.0"

# Limpiar al salir
echo "🧹 Deteniendo port-forward..."
kill $PF_PID 2>/dev/null

echo "✓ Terminado"
