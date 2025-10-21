#!/bin/bash

# Script para desplegar Kafka, RabbitMQ y Grafana en GKE

set -e

NAMESPACE="weather-system"

echo "=== Instalando NGINX Ingress Controller ==="
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx || true
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

echo "=== Instalando Strimzi Kafka Operator ==="
helm repo add strimzi https://strimzi.io/charts || true
helm repo update
helm install strimzi strimzi/strimzi-kafka-operator \
  --namespace weather-system \
  --create-namespace

echo "=== Esperando a que el operador de Kafka esté listo ==="
kubectl wait --for=condition=ready pod \
  -l name=strimzi-cluster-operator \
  -n weather-system \
  --timeout=300s

echo "=== Desplegando Kafka Cluster ==="
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: weather-kafka
  namespace: weather-system
spec:
  kafka:
    version: 3.6.0
    replicas: 1
    resources:
      requests:
        memory: "512Mi"
        cpu: "250m"
      limits:
        memory: "1Gi"
        cpu: "500m"
    storage:
      type: ephemeral
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
  zookeeper:
    replicas: 1
    resources:
      requests:
        memory: "256Mi"
        cpu: "100m"
      limits:
        memory: "512Mi"
        cpu: "250m"
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

echo "=== Creando topic de Kafka ==="
sleep 10
kubectl apply -f - <<EOF
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: weather-tweets
  namespace: weather-system
  labels:
    strimzi.io/cluster: weather-kafka
spec:
  partitions: 3
  replicationFactor: 1
EOF

echo "=== Instalando RabbitMQ con Helm ==="
helm repo add bitnami https://charts.bitnami.com/bitnami || true
helm repo update
helm install rabbitmq bitnami/rabbitmq \
  --namespace weather-system \
  --set auth.username=guest \
  --set auth.password=guest \
  --set persistence.enabled=false \
  --set resources.requests.memory="256Mi" \
  --set resources.requests.cpu="100m"

echo "=== Instalando Grafana con Helm ==="
helm repo add grafana https://grafana.github.io/helm-charts || true
helm repo update
helm install grafana grafana/grafana \
  --namespace weather-system \
  --set adminPassword=admin \
  --set persistence.enabled=false \
  --set resources.requests.memory="256Mi" \
  --set resources.requests.cpu="100m"

echo "=== Despliegue completado ==="
echo "Esperando a que los servicios estén listos..."
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=rabbitmq \
  -n weather-system \
  --timeout=300s || true

kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/name=grafana \
  -n weather-system \
  --timeout=300s || true

echo "=== Servicios desplegados ==="
kubectl get all -n weather-system
