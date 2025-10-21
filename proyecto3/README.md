# 🌦️ Proyecto 3: Tweets del Clima - Sistema Distribuido en Kubernetes

**Estudiante:** Luis Pablo García  
**Carnet:** 202200129  
**Municipio Asignado:** Chinautla (último dígito 9)  
**Curso:** Sistemas Operativos 1  

---

## 📋 Descripción General

Sistema distribuido y escalable para procesar "tweets" sobre el clima local utilizando **Google Kubernetes Engine (GKE)**. El sistema integra:

- **API REST en Rust** para recibir solicitudes
- **Servicios en Go** para procesar datos
- **Message Brokers** (Kafka y RabbitMQ) para comunicación asíncrona
- **Valkey (Redis)** para almacenamiento en memoria
- **Grafana** para visualización de datos
- **Locust** para pruebas de carga
- **Zot** como Container Registry

---

## 🏗️ Arquitectura

```
┌─────────────────┐
│     Locust      │ (Generador de carga)
└────────┬────────┘
         │ HTTP
         ▼
┌──────────────────────┐
│  NGINX Ingress       │
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│   API REST (Rust)    │ (Recibe tweets)
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│  Go Processor        │ (Procesa datos)
└─────────┬────────────┘
          │
    ┌─────┴─────┐
    │           │
    ▼           ▼
┌────────┐  ┌─────────┐
│ Kafka  │  │RabbitMQ │ (Message Brokers)
└────────┘  └─────────┘
    │           │
    ▼           ▼
┌──────────────────────┐
│     Valkey (DB)      │ (Almacenamiento)
└─────────┬────────────┘
          │
          ▼
┌──────────────────────┐
│     Grafana          │ (Visualización)
└──────────────────────┘
```

---

## 📁 Estructura del Proyecto

```
proyecto3/
├── docker/
│   ├── Dockerfile.rust          # Imagen Docker para API Rust
│   ├── Dockerfile.go            # Imagen Docker para Go Processor
│   └── .gitkeep
├── rust-api/
│   ├── src/
│   │   └── main.rs              # Código fuente API Rust
│   └── Cargo.toml               # Dependencias Rust
├── go-processor/
│   ├── main.go                  # Código fuente Go Processor
│   └── go.mod                   # Módulo Go
├── k8s/
│   ├── base-deployment.yaml     # Deployments principales + Ingress
│   ├── kafka.yaml               # Kafka + Zookeeper
│   ├── rabbitmq.yaml            # RabbitMQ
│   └── valkey-grafana.yaml      # Valkey + Grafana
├── locust/
│   ├── locustfile.py            # Script de pruebas de carga
│   └── requirements.txt
├── scripts/
│   ├── deploy.sh                # Script para desplegar todo
│   └── build-and-push.sh        # Script para construir y enviar a Zot
└── README.md                    # Este archivo
```

---

## 🚀 Guía de Despliegue Rápido

### Prerequisitos

- Cluster GKE activo y funcional
- `kubectl` configurado
- Docker instalado (para construir imágenes)
- NGINX Ingress Controller (se instala automáticamente)

### Paso 1: Crear la VM con Zot

Consulta el archivo `SETUP_VM_ZOT.md` en la raíz del proyecto para crear y configurar la VM con Zot Registry.

Una vez tengas la VM con Zot funcionando, obtén su IP:

```bash
gcloud compute instances describe zot-registry --zone us-central1-c \
  --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

### Paso 2: Construir y Enviar Imágenes a Zot

```bash
# Desde tu máquina local
cd /home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO

# Construir y enviar (reemplaza ZOT_IP con la IP de tu VM)
bash proyecto3/scripts/build-and-push.sh ZOT_IP:5000
```

### Paso 3: Desplegar en Kubernetes

```bash
# Desde tu Cloud Shell
cd proyecto3

# Hacer el script ejecutable
chmod +x scripts/deploy.sh

# Ejecutar el despliegue
bash scripts/deploy.sh
```

El script:
- Crea el namespace `weather-tweets`
- Instala NGINX Ingress Controller
- Despliega Kafka + Zookeeper
- Despliega RabbitMQ
- Despliega Valkey
- Despliega Grafana
- Despliega la API Rust y Go Processor
- Espera a que todos los pods estén listos

### Paso 4: Acceder a los Servicios

Después del despliegue, verifica los servicios:

```bash
# Ver todos los recursos
kubectl get all -n weather-tweets

# Ver ingress
kubectl get ingress -n weather-tweets

# Obtener IP del Ingress
kubectl get ingress weather-ingress -n weather-tweets -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Port-forward a Grafana (si prefieres)
kubectl port-forward -n weather-tweets svc/grafana-service 3000:3000
```

---

## 📊 Acceso a Grafana

1. **URL:** `http://<INGRESS_IP>:3000` o `http://localhost:3000` (si usas port-forward)
2. **Usuario:** `admin`
3. **Contraseña:** `admin`

Grafana ya está preconfigurado para conectarse a Valkey en la fuente de datos.

---

## 🔥 Pruebas de Carga con Locust

### Instalación de Locust

```bash
pip install -r proyecto3/locust/requirements.txt
```

### Ejecutar Locust

```bash
# Obtén la IP del Ingress
INGRESS_IP=$(kubectl get ingress weather-ingress -n weather-tweets -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Ejecuta Locust
locust -f proyecto3/locust/locustfile.py --host=http://$INGRESS_IP
```

Luego:
1. Abre http://localhost:8089 en tu navegador
2. Ingresa:
   - **Number of users:** 10
   - **Spawn rate:** 2
   - Click en **Start swarming**

---

## 📈 Componentes Detallados

### 1. API REST (Rust)

**Puerto:** 8080  
**Endpoints:**
- `GET /health` - Verificar salud del API
- `POST /tweet` - Recibir un tweet del clima
- `GET /stats` - Obtener estadísticas

**Ejemplo:**
```bash
curl -X POST http://localhost:8080/tweet \
  -H "Content-Type: application/json" \
  -d '{
    "municipality": "chinautla",
    "temperature": 28,
    "humidity": 75,
    "weather": "cloudy"
  }'
```

### 2. Procesador (Go)

**Puerto:** 8081  
**Endpoints:**
- `GET /health` - Verificar salud del procesador
- `POST /process` - Procesar un tweet
- `GET /stats` - Obtener estadísticas

### 3. Kafka

**Puerto:** 9092  
- Tópico: `weather-tweets`
- Broker: `kafka-service:9092`

### 4. RabbitMQ

**Puerto:** 5672 (AMQP)  
**Management UI:** 15672  
- Queue: `weather.tweets`
- Usuario: `guest`
- Contraseña: `guest`

### 5. Valkey (Redis)

**Puerto:** 6379  
- Almacena datos procesados
- Estructura: `tweet:<id> → JSON`

### 6. Grafana

**Puerto:** 3000  
- Visualiza datos de Valkey
- Dashboards preconfigurados

---

## 🛠️ Comandos Útiles

```bash
# Ver todos los pods
kubectl get pods -n weather-tweets

# Ver logs de un pod
kubectl logs -n weather-tweets deployment/rust-api

# Ejecutar comandos dentro de un pod
kubectl exec -it -n weather-tweets pod/rust-api-xxx -- /bin/bash

# Ver recursos usados
kubectl top nodes
kubectl top pods -n weather-tweets

# Eliminar todo el despliegue
kubectl delete namespace weather-tweets

# Hacer port-forward a un servicio
kubectl port-forward -n weather-tweets svc/valkey-service 6379:6379
```

---

## 📝 Respuestas a Preguntas del Proyecto

### ¿Por qué usar Kubernetes?

Kubernetes proporciona:
- **Escalabilidad automática** mediante HPA
- **Balanceo de carga** automático
- **Recuperación de fallos** (restart de pods)
- **Gestión de recursos** eficiente
- **Deployments declarativos**

### ¿Kafka vs RabbitMQ?

| Aspecto | Kafka | RabbitMQ |
|--------|-------|----------|
| Tipo | Log distribuido | Message Broker |
| Throughput | Muy alto (>1M msgs/s) | Moderado (1K-10K msgs/s) |
| Persistencia | Nativa | Configurable |
| Latencia | Media (10-100ms) | Baja (<10ms) |
| Caso de uso | Streaming de eventos | Tareas asíncronas |

**Para este proyecto:** Kafka es mejor para eventos del clima continuos; RabbitMQ para tareas discretas.

### ¿Valkey vs Redis?

Valkey es un fork de Redis mantenido por Linux Foundation:
- Compatible con Redis
- Mejor para licencias open-source
- Mejor desarrollo comunitario

**Para este proyecto:** Funcionan igual, usando Valkey por licencia.

### ¿gRPC vs HTTP?

| Aspecto | HTTP | gRPC |
|--------|------|------|
| Protocolo | HTTP/1.1 | HTTP/2 |
| Serialización | JSON | Protocol Buffers |
| Bidireccional | No | Sí |
| Performance | Buena | Excelente |
| Debugging | Fácil | Complejo |

**Para este proyecto:** HTTP para Locust-API, gRPC entre servicios internos (futura mejora).

---

## 🔄 Flujo de Datos

1. **Locust** genera tweets del clima (JSON)
2. **Ingress** enruta a **API Rust** (puerto 8080)
3. **API Rust** recibe el tweet y lo envía a **Go Processor** (puerto 8081)
4. **Go Processor** publica en **Kafka** y **RabbitMQ**
5. **Consumidores** leen de Kafka y RabbitMQ
6. **Consumidores** almacenan datos en **Valkey**
7. **Grafana** consulta **Valkey** y visualiza los datos

---

## 📋 Estructura JSON de Tweets

```json
{
  "municipality": "chinautla",
  "temperature": 28,
  "humidity": 75,
  "weather": "cloudy"
}
```

**Municipios válidos:**
- `mixco` (carnet 0,1,2)
- `guatemala` (carnet 3,4,5)
- `amatitlan` (carnet 6,7)
- `chinautla` (carnet 8,9) ← Tu municipio

**Condiciones climáticas válidas:**
- `sunny`
- `cloudy`
- `rainy`
- `foggy`

---

## 🎯 Dashboard Grafana Requerido

El dashboard debe mostrar (para municipio Chinautla):

1. **Total de reportes por condición climática** (Gráfica de barras)
   - Eje X: Condición climática (sunny, cloudy, rainy, foggy)
   - Eje Y: Cantidad de tweets

2. **Temperatura promedio** (Indicador)
3. **Humedad promedio** (Indicador)
4. **Total de tweets recibidos** (Número)

---

## 🐛 Troubleshooting

### Los pods no inician

```bash
# Ver eventos
kubectl describe pod -n weather-tweets <pod-name>

# Ver logs
kubectl logs -n weather-tweets <pod-name>

# Verificar recursos disponibles
kubectl top nodes
```

### Ingress no tiene IP

```bash
# A veces tarda, espera 2-3 minutos
kubectl get ingress -n weather-tweets --watch
```

### No puedo acceder a Grafana

```bash
# Verifica que el servicio existe
kubectl get svc grafana-service -n weather-tweets

# Usa port-forward si no tienes IP externa
kubectl port-forward -n weather-tweets svc/grafana-service 3000:3000
```

### Valkey está lleno

```bash
# Conectarte a Valkey
kubectl exec -it -n weather-tweets pod/valkey-xxx -- redis-cli

# Limpiar todos los datos
> FLUSHALL

# Ver tamaño de la DB
> DBSIZE
```

---

## 📚 Referencias

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Google Kubernetes Engine](https://cloud.google.com/kubernetes-engine/docs)
- [Actix-web (Rust)](https://actix.rs/)
- [Go HTTP](https://golang.org/pkg/net/http/)
- [Apache Kafka](https://kafka.apache.org/)
- [RabbitMQ](https://www.rabbitmq.com/)
- [Grafana](https://grafana.com/)
- [Zot Registry](https://zotregistry.io/)

---

## 📅 Cronograma de Desarrollo

- **Semana 1:** Configuración de GCP, VM Zot, API Rust y servicios Go básicos
- **Semana 2:** Kafka, RabbitMQ, consumidores y Valkey
- **Semana 3:** Grafana, pruebas de carga, HPA
- **Semana 4:** Documentación y entrega final

---

## ✅ Checklist Previo a Calificación

- [ ] Cluster GKE activo y funcional
- [ ] VM con Zot Registry en ejecución
- [ ] Todas las imágenes Docker en Zot
- [ ] Todos los pods en estado "Running"
- [ ] Ingress con IP asignada
- [ ] Grafana accesible
- [ ] Locust listo para generar carga
- [ ] Base de datos Valkey vacía
- [ ] Repositorio GitHub con todo el código
- [ ] Documentación técnica completa

---

## 👤 Información del Estudiante

- **Nombre:** Luis Pablo García
- **Carnet:** 202200129
- **Municipio:** Chinautla
- **Repositorio:** [GitHub](https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO)

---

**Última actualización:** Octubre 2025  
**Estado:** En desarrollo
