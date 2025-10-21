# 📋 Instrucciones de Despliegue en Cloud Shell

## ⚠️ IMPORTANTE: Lee esto primero

Tu carnet es **202200129** → Municipio **CHINAUTLA**  
Tu cluster está en zona **us-central1-c** → Nombre **sopes1**  
Tu proyecto es **proyecto-3-475405**

---

## 🚀 Paso 1: Ejecutar desde Cloud Shell

Copia y pega esto en tu Cloud Shell:

```bash
# Clonar el repositorio
git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO.git

# Navegar a la carpeta
cd 202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3

# Hacer scripts ejecutables
chmod +x scripts/setup-cluster.sh
chmod +x scripts/quick-deploy.sh
chmod +x scripts/build-and-push.sh
chmod +x scripts/deploy.sh

# Ejecutar despliegue rápido completo
bash scripts/quick-deploy.sh
```

---

## 📝 Paso a Paso Detallado (si prefieres hacerlo manualmente)

### 1. Configurar el Cluster

```bash
gcloud config set project proyecto-3-475405
gcloud config set compute/zone us-central1-c

gcloud container clusters get-credentials sopes1 \
  --zone us-central1-c \
  --project proyecto-3-475405

# Verificar que estás conectado
kubectl cluster-info
kubectl get nodes
```

### 2. Instalar NGINX Ingress Controller

```bash
# Instalar
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Esperar a que esté listo
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# Verificar
kubectl get ingress -n ingress-nginx
```

### 3. Clonar el Repositorio

```bash
git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO.git

cd 202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3

chmod +x scripts/*.sh
```

### 4. Desplegar Componentes (en orden)

```bash
# Primero: Crear namespace
kubectl apply -f k8s/base-deployment.yaml

# Segundo: Kafka + Zookeeper
kubectl apply -f k8s/kafka.yaml

# Esperar un poco
sleep 30

# Tercero: RabbitMQ
kubectl apply -f k8s/rabbitmq.yaml

# Cuarto: Valkey + Grafana
kubectl apply -f k8s/valkey-grafana.yaml

# Quinto: API Rust + Go + Ingress (ya incluido en base-deployment.yaml)
# Está hecho en el primer paso
```

### 5. Verificar que Todo Esté Corriendo

```bash
# Ver todos los pods
kubectl get pods -n weather-tweets --watch

# Ver servicios
kubectl get svc -n weather-tweets

# Ver ingress
kubectl get ingress -n weather-tweets

# Ver si hay errores
kubectl describe pod -n weather-tweets <nombre-del-pod>

# Ver logs
kubectl logs -n weather-tweets <nombre-del-pod>
```

### 6. Obtener IPs Externas

```bash
# IP del Ingress (para Locust y acceso a APIs)
kubectl get ingress weather-ingress -n weather-tweets \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# IP de Grafana
kubectl get svc grafana-service -n weather-tweets \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# IP de RabbitMQ Management UI
kubectl get svc rabbitmq-management -n weather-tweets \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

---

## 🔍 Verificación Rápida

Una vez desplegado, verifica que todo funciona:

```bash
# 1. Verificar pods
INGRESS_IP=$(kubectl get ingress weather-ingress -n weather-tweets \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# 2. Probar API Rust
curl http://$INGRESS_IP/api/health

# 3. Probar Processor
curl http://$INGRESS_IP/process

# 4. Ver estadísticas
curl http://$INGRESS_IP/api/stats
```

---

## 🌍 URLs de Acceso (después del despliegue)

Reemplaza `<IP>` con la IP que obtuviste en "Obtener IPs Externas"

- **API Rust:** `http://<INGRESS_IP>/api/health`
- **Processor:** `http://<INGRESS_IP>/process`
- **Grafana:** `http://<GRAFANA_IP>:3000` (usuario: admin, contraseña: admin)
- **RabbitMQ UI:** `http://<RABBITMQ_IP>:15672` (usuario: guest, contraseña: guest)
- **Kafka:** Accesible internamente en `kafka-service:9092`
- **Valkey:** Accesible internamente en `valkey-service:6379`

---

## 🔥 Pruebas de Carga con Locust (en tu máquina local)

Una vez todo desplegado en Kubernetes:

```bash
# En tu máquina local (donde tienes Locust)
pip install locust

# Obtén la IP del Ingress (desde Cloud Shell)
INGRESS_IP=<tu-ip-del-ingress>

# Ejecuta Locust
locust -f /home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3/locust/locustfile.py \
  --host=http://$INGRESS_IP

# Se abrirá en http://localhost:8089
# - Number of users: 10
# - Spawn rate: 2
# - Click "Start swarming"
```

---

## 🛠️ Troubleshooting

### Los pods no inician

```bash
# Ver eventos
kubectl describe pod -n weather-tweets <pod-name>

# Ver logs
kubectl logs -n weather-tweets <pod-name>

# Reiniciar deployment
kubectl rollout restart deployment/rust-api -n weather-tweets
```

### Ingress no tiene IP

```bash
# A veces tarda 2-3 minutos
kubectl get ingress -n weather-tweets --watch

# Verificar NGINX
kubectl get svc -n ingress-nginx
```

### Valkey lleno

```bash
# Conectarse a Valkey
kubectl exec -it -n weather-tweets deployment/valkey -- redis-cli

# Dentro de redis-cli:
> FLUSHALL  # Limpiar todo
> DBSIZE    # Ver tamaño
> KEYS *    # Ver todas las claves
> EXIT
```

### Verificar Kafka

```bash
# Entrar al pod de Kafka
kubectl exec -it -n weather-tweets deployment/kafka -- bash

# Dentro del pod:
kafka-topics --list --bootstrap-server localhost:9092
kafka-topics --create --topic weather-tweets --bootstrap-server localhost:9092
```

### Verificar RabbitMQ

```bash
# Ver queue
RABBITMQ_POD=$(kubectl get pod -n weather-tweets -l app=rabbitmq -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it -n weather-tweets $RABBITMQ_POD -- rabbitmqctl list_queues
```

---

## 📊 Comandos Útiles

```bash
# Ver todo en una línea
kubectl get all -n weather-tweets

# Ver eventos en tiempo real
kubectl get events -n weather-tweets --watch

# Port-forward (si necesitas acceso local)
kubectl port-forward -n weather-tweets svc/grafana-service 3000:3000
kubectl port-forward -n weather-tweets svc/valkey-service 6379:6379

# Eliminar todo (si necesitas empezar de cero)
kubectl delete namespace weather-tweets

# Ver uso de recursos
kubectl top nodes
kubectl top pods -n weather-tweets
```

---

## ✅ Checklist Final para Calificación

- [ ] Cluster GKE activo
- [ ] VM con Zot Registry en ejecución
- [ ] NGINX Ingress Controller instalado
- [ ] Todos los pods en estado "Running"
- [ ] Ingress con IP asignada
- [ ] Grafana accesible en puerto 3000
- [ ] Valkey vacío (FLUSHALL)
- [ ] Locust listo para ejecutar
- [ ] Repositorio GitHub actualizado
- [ ] Documentación técnica completa

---

**¡Listo! Ahora ejecuta: `bash scripts/quick-deploy.sh`**
