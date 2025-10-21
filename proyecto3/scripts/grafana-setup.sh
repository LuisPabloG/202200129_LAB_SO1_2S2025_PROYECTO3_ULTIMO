#!/bin/bash

# Script para configurar Grafana con plugin de Redis
# Este script se ejecuta como init container en Grafana

set -e

echo "🚀 Configurando Grafana con plugin de Redis..."

# 1. Instalar plugin de Redis
grafana-cli admin reset-admin-password admin

# Esperar a que Grafana inicie
echo "⏳ Esperando a que Grafana esté listo..."
for i in {1..30}; do
  if curl -s http://localhost:3000/api/health > /dev/null; then
    echo "✅ Grafana está listo"
    break
  fi
  echo "Intento $i/30..."
  sleep 2
done

# 2. Obtener API token de admin
echo "🔑 Obteniendo token de Grafana..."
AUTH=$(echo -n "admin:admin" | base64)

# 3. Instalar plugin de Redis si no está instalado
echo "📦 Instalando plugin de Redis..."
grafana-cli plugins install redis-datasource || true

# 4. Crear Data Source de Redis/Valkey
echo "📊 Creando Data Source de Valkey..."

DS_PAYLOAD=$(cat <<EOF
{
  "name": "Valkey",
  "type": "redis-datasource",
  "access": "proxy",
  "isDefault": true,
  "jsonData": {
    "client": "standalone",
    "tlsAuth": false,
    "tlsSkipVerify": true
  },
  "secureJsonData": {},
  "url": "http://valkey.weather-system:6379"
}
EOF
)

curl -s -X POST http://localhost:3000/api/datasources \
  -H "Authorization: Bearer $AUTH" \
  -H "Content-Type: application/json" \
  -d "$DS_PAYLOAD" || echo "Data Source ya existe"

echo "✅ Configuración completada"
