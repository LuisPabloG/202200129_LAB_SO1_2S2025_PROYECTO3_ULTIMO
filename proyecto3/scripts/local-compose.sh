#!/bin/bash

###############################################################################
# Script para ejecutar el sistema localmente con Docker Compose
# Carnet: 202200129
###############################################################################

set -e

COMMAND="${1:-up}"
PROJECT_DIR=$(pwd)

echo "======================================"
echo "Weather Tweets System - Local Setup"
echo "======================================"
echo "Comando: $COMMAND"
echo ""

case $COMMAND in
  up)
    echo "Iniciando servicios..."
    docker-compose -f proyecto3/docker-compose.yml up -d
    sleep 5
    echo ""
    echo "✓ Servicios iniciados"
    echo ""
    echo "Endpoints disponibles:"
    echo "  - Grafana: http://localhost:3000 (admin/admin)"
    echo "  - RabbitMQ: http://localhost:15672 (guest/guest)"
    echo "  - Prometheus: http://localhost:9090"
    echo "  - Kafka: localhost:9092"
    echo "  - Valkey: localhost:6379"
    echo ""
    docker-compose -f proyecto3/docker-compose.yml ps
    ;;

  down)
    echo "Deteniendo servicios..."
    docker-compose -f proyecto3/docker-compose.yml down -v
    echo "✓ Servicios detenidos"
    ;;

  logs)
    docker-compose -f proyecto3/docker-compose.yml logs -f
    ;;

  ps)
    docker-compose -f proyecto3/docker-compose.yml ps
    ;;

  build)
    echo "Construyendo imágenes..."
    docker-compose -f proyecto3/docker-compose.yml build
    echo "✓ Imágenes construidas"
    ;;

  *)
    echo "Uso: $0 {up|down|logs|ps|build}"
    exit 1
    ;;
esac
