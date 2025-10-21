#!/bin/bash

# Script para configurar Grafana con Redis desde Cloud Shell
# Ejecuta este script desde Google Cloud Shell

echo "🚀 Configurando Grafana con plugin de Redis en GKE..."

# 1. Eliminar Grafana viejo
echo "🗑️  Removiendo Grafana antiguo..."
kubectl delete deployment grafana -n weather-system 2>/dev/null || echo "Grafana no encontrado"
sleep 2

# 2. Aplicar nuevo Grafana con Redis
echo "📦 Desplegando Grafana con plugin de Redis..."
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-redis
  namespace: weather-system
  labels:
    app: grafana-redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-redis
  template:
    metadata:
      labels:
        app: grafana-redis
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
          name: http
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: admin
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin
        - name: GF_INSTALL_PLUGINS
          value: redis-datasource
        - name: GF_USERS_ALLOW_SIGN_UP
          value: "false"
        - name: GF_SERVER_ROOT_URL
          value: http://localhost:3000
        resources:
          requests:
            cpu: 100m
            memory: 256Mi
          limits:
            cpu: 300m
            memory: 512Mi
        livenessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
      volumes:
      - name: grafana-storage
        emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: grafana-redis-service
  namespace: weather-system
spec:
  selector:
    app: grafana-redis
  ports:
  - port: 3000
    targetPort: 3000
    protocol: TCP
  type: ClusterIP
EOF

# 3. Esperar a que Grafana esté listo
echo "⏳ Esperando a que Grafana inicie..."
kubectl wait --for=condition=available --timeout=300s deployment/grafana-redis -n weather-system || true

# 4. Obtener el pod de Grafana
echo "🔍 Obteniendo pod de Grafana..."
GRAFANA_POD=$(kubectl get pods -n weather-system -l app=grafana-redis -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $GRAFANA_POD"

# 5. Esperar a que esté completamente listo
echo "⏳ Esperando a que Grafana responda..."
kubectl exec -n weather-system $GRAFANA_POD -- bash -c 'for i in {1..30}; do if curl -s http://localhost:3000/api/health > /dev/null; then echo "✅ Grafana listo"; exit 0; fi; echo "Intento $i/30..."; sleep 2; done'

# 6. Obtener token de admin (opcional)
echo "🔐 Grafana está listo para usar"
echo "   Usuario: admin"
echo "   Contraseña: admin"

# 7. Eliminar LoadBalancer viejo si existe
kubectl delete service grafana-lb -n weather-system 2>/dev/null || true

# 8. Crear nuevo LoadBalancer
echo "📡 Creando LoadBalancer para Grafana..."
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: grafana-lb
  namespace: weather-system
spec:
  type: LoadBalancer
  selector:
    app: grafana-redis
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
EOF

# 9. Esperar IP externa
echo "⏳ Esperando IP externa..."
sleep 10

# 10. Mostrar IPs
echo ""
echo "✅ GRAFANA CONFIGURADO"
echo ""
kubectl get svc grafana-lb -n weather-system -o wide

echo ""
echo "📊 Próximo paso: Acceder a Grafana y crear dashboard con datos de Valkey"
echo "   El data source de Redis debería auto-detectarse en:"
echo "   http://valkey.weather-system:6379"
