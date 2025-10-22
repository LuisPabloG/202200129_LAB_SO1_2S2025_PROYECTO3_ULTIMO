#!/bin/bash

# Script para configurar Data Source de Valkey en Grafana
# Uso: ./setup-grafana-datasource.sh <GRAFANA_IP>

GRAFANA_IP=${1:-34.60.56.92}
GRAFANA_URL="http://$GRAFANA_IP"
ADMIN_USER="admin"
ADMIN_PASS="admin"

echo "🚀 Configurando Data Source de Valkey en Grafana..."
echo "   URL: $GRAFANA_URL"

# 1. Esperar a que Grafana esté listo
echo "⏳ Esperando a que Grafana responda..."
for i in {1..30}; do
  if curl -s "$GRAFANA_URL/api/health" > /dev/null; then
    echo "✅ Grafana está listo"
    break
  fi
  echo "   Intento $i/30..."
  sleep 2
done

# 2. Obtener API key
echo "🔑 Obteniendo API key..."
API_KEY=$(curl -s -X POST "$GRAFANA_URL/api/auth/admin/generic-oauth-login" \
  -H "Content-Type: application/json" \
  -d "{\"user\":\"$ADMIN_USER\",\"password\":\"$ADMIN_PASS\"}" 2>/dev/null | jq -r '.token' 2>/dev/null || echo "")

# Si no funciona con ese método, intentamos autenticación básica
if [ -z "$API_KEY" ] || [ "$API_KEY" == "null" ]; then
  echo "🔐 Usando autenticación básica..."
  BASIC_AUTH=$(echo -n "$ADMIN_USER:$ADMIN_PASS" | base64)
else
  BASIC_AUTH=""
fi

# 3. Crear/Actualizar Data Source de Valkey
echo "📊 Creando Data Source de Valkey..."

# Intentar crear el data source
if [ -n "$BASIC_AUTH" ]; then
  curl -s -X POST "$GRAFANA_URL/api/datasources" \
    -H "Authorization: Basic $BASIC_AUTH" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Valkey",
      "type": "redis-datasource",
      "access": "proxy",
      "isDefault": true,
      "jsonData": {
        "client": "standalone",
        "tlsAuth": false,
        "tlsSkipVerify": true
      },
      "url": "http://valkey.weather-system:6379"
    }'
else
  curl -s -X POST "$GRAFANA_URL/api/datasources" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d '{
      "name": "Valkey",
      "type": "redis-datasource",
      "access": "proxy",
      "isDefault": true,
      "jsonData": {
        "client": "standalone",
        "tlsAuth": false,
        "tlsSkipVerify": true
      },
      "url": "http://valkey.weather-system:6379"
    }'
fi

echo ""
echo "✅ Data Source configurado"
echo ""
echo "📍 Próximo paso: Crear Dashboard"
echo "   1. Ve a: Dashboards → New Dashboard"
echo "   2. Add Panel"
echo "   3. Data Source: Valkey"
echo "   4. Query: GET count:chinautla"
echo ""
echo "🌐 Accede a Grafana en: $GRAFANA_URL"
