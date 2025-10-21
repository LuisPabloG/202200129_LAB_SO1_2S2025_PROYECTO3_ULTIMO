#!/bin/bash

# Script principal de deployment

set -e

NAMESPACE="weather-system"
PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
CLUSTER_ZONE="us-central1-c"

echo "======================================"
echo "Proyecto 3: Weather Tweets System"
echo "Carnet: 202200129"
echo "======================================"

# Configurar kubectl
echo "Configurando kubectl para conectarse a GKE..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone $CLUSTER_ZONE --project $PROJECT_ID

# Crear namespace
echo "Creando namespace..."
kubectl apply -f k8s/namespaces/namespace.yaml

# Desplegar infraestructura
echo "Desplegando infraestructura (Kafka, RabbitMQ, Grafana)..."
chmod +x scripts/deploy-infrastructure.sh
./scripts/deploy-infrastructure.sh

# Esperar a que Kafka esté listo
echo "Esperando a que Kafka esté completamente listo..."
sleep 30

# Desplegar componentes de la aplicación
echo "Desplegando componentes de la aplicación..."
kubectl apply -f k8s/deployments/valkey.yaml
sleep 5
kubectl apply -f k8s/services/valkey-service.yaml
sleep 5

kubectl apply -f k8s/deployments/weather-api-rust.yaml
kubectl apply -f k8s/services/weather-api-service.yaml
sleep 5

kubectl apply -f k8s/deployments/weather-processor-go.yaml
kubectl apply -f k8s/services/weather-processor-service.yaml
sleep 5

kubectl apply -f k8s/deployments/kafka-consumer.yaml
kubectl apply -f k8s/deployments/rabbitmq-consumer.yaml
sleep 5

# Desplegar Ingress
echo "Desplegando Ingress Controller..."
kubectl apply -f k8s/ingress/weather-ingress.yaml

# Desplegar HPA
echo "Desplegando Horizontal Pod Autoscaler..."
kubectl apply -f k8s/hpa/hpa-rust.yaml

# Mostrar estado
echo ""
echo "======================================"
echo "Despliegue completado!"
echo "======================================"
echo ""
echo "Estado del cluster:"
kubectl get all -n $NAMESPACE
echo ""
echo "Ingress:"
kubectl get ingress -n $NAMESPACE
echo ""
echo "Para acceder a Grafana:"
echo "kubectl port-forward -n $NAMESPACE svc/grafana 3000:80"
echo ""
echo "Para acceder a RabbitMQ Management:"
echo "kubectl port-forward -n $NAMESPACE svc/rabbitmq 15672:15672"
