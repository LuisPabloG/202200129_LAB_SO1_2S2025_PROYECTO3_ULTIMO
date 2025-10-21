# Documentación Técnica - Proyecto 3: Weather Tweets System

## Información del Estudiante
- **Carnet**: 202200129
- **Municipio Asignado**: Chinautla (último dígito 9)
- **Proyecto**: Arquitectura Distribuida en la Nube con Kubernetes

## 1. Arquitectura General

El sistema está diseñado como una arquitectura de microservicios completamente distribuida y escalable en Google Kubernetes Engine (GKE).

### 1.1 Componentes principales

```
Locust (Generación de Carga)
    ↓
NGINX Ingress Controller
    ↓
Weather API (Rust) - API REST
    ↓
Weather Processor (Go) - gRPC Client/Server
    ├─→ Kafka Writer
    └─→ RabbitMQ Writer
    ↓
Message Brokers (Kafka & RabbitMQ)
    ↓
Consumidores (Go)
    ├─→ Kafka Consumer
    └─→ RabbitMQ Consumer
    ↓
Valkey (Base de datos en memoria)
    ↓
Grafana (Visualización)
```

## 2. Estructura del Proyecto

```
proyecto3/
├── src/
│   ├── rust/                    # API REST en Rust
│   │   ├── Cargo.toml
│   │   └── src/
│   │       └── main.rs
│   ├── go/                      # Servicios en Go
│   │   ├── go.mod
│   │   ├── api/                 # API/gRPC Processor
│   │   ├── grpc_server/         # gRPC Server
│   │   └── consumer/            # Consumidores
│   └── weathertweet.proto       # Definición de gRPC
├── docker/                      # Dockerfiles
│   ├── Dockerfile.rust
│   ├── Dockerfile.go
│   └── Dockerfile.locust
├── k8s/                         # Manifiestos de Kubernetes
│   ├── namespaces/
│   ├── deployments/
│   ├── services/
│   ├── ingress/
│   └── hpa/
├── scripts/
│   ├── locustfile.py            # Script de prueba de carga
│   ├── deploy-all.sh            # Script principal de deployment
│   └── deploy-infrastructure.sh # Instalación de componentes
└── docs/
    └── README.md
```

## 3. Tecnologías Utilizadas

### Backend
- **Rust**: API REST con Actix-web para alta concurrencia
- **Go**: Servicios gRPC para procesamiento y consumo de mensajes
- **gRPC**: Comunicación entre servicios

### Message Brokers
- **Kafka** (Strimzi): Para procesamiento de eventos distribuido
- **RabbitMQ**: Para enrutamiento de mensajes tradicional

### Almacenamiento
- **Valkey**: Base de datos en memoria (compatible con Redis)

### Orquestación
- **Kubernetes (GKE)**: Orquestación de contenedores
- **NGINX Ingress**: Controlador de Ingress
- **HPA**: Auto-escalado horizontal

### Visualización
- **Grafana**: Dashboards en tiempo real

### Testing
- **Locust**: Generación de carga masiva

## 4. Deployment en GKE

### 4.1 Preparación

```bash
# Configurar gcloud
gcloud config set project proyecto-3-475405
gcloud container clusters get-credentials sopes1 --zone us-central1-c

# Crear namespace
kubectl create namespace weather-system
```

### 4.2 Instalación de componentes

Los componentes se instalan automáticamente mediante Helm:

1. **NGINX Ingress Controller**
2. **Strimzi Kafka Operator**
3. **Kafka Cluster**
4. **RabbitMQ**
5. **Grafana**

### 4.3 Despliegue de aplicación

```bash
# Ejecutar el script de deployment
chmod +x scripts/deploy-all.sh
./scripts/deploy-all.sh
```

## 5. Especificación de Tweets

### 5.1 Estructura JSON

```json
{
  "municipality": 4,    // 1=mixco, 2=guatemala, 3=amatitlan, 4=chinautla
  "temperature": 25,    // Celsius
  "humidity": 65,       // Porcentaje
  "weather": 2          // 1=sunny, 2=cloudy, 3=rainy, 4=foggy
}
```

### 5.2 Flujo de procesamiento

1. Locust envía peticiones POST a `/weather`
2. API Rust recibe y válida el tweet
3. Reenvía al Processor Go a través de gRPC
4. Go publica en Kafka y RabbitMQ simultáneamente
5. Consumidores leen de ambos brokers
6. Almacenan datos en Valkey
7. Grafana visualiza los datos en tiempo real

## 6. Métricas y Monitoreo

### 6.1 Datos almacenados en Valkey

- Tweets por municipio
- Promedio de temperatura
- Promedio de humedad
- Conteo por condición climática
- Timestamps de recepción

### 6.2 Dashboard de Grafana

El dashboard muestra:
- Total de tweets procesados
- Tweets por municipio
- Temperatura promedio por municipio
- Tendencias de humedad
- Distribución de condiciones climáticas

## 7. Pruebas de Carga

### 7.1 Locust Configuration

- **Usuarios concurrentes**: Configurables (recomendado 10-100)
- **Tasa de generación**: 0.1-0.5 segundos entre peticiones
- **Duración**: Configurable desde GUI de Locust

### 7.2 Análisis de Rendimiento

Se analiza:
- Latencia de respuesta
- Throughput (peticiones/segundo)
- Comportamiento con 1 vs 2 réplicas
- Consumo de recursos CPU/Memoria

## 8. Escalado

### 8.1 HPA para Weather API (Rust)

- **Min replicas**: 1
- **Max replicas**: 3
- **Target CPU**: 30%
- **Target Memory**: 80%

### 8.2 Scaling manual

```bash
# Escalar Weather API
kubectl scale deployment weather-api-rust --replicas=3 -n weather-system

# Escalar Go Processor
kubectl scale deployment weather-processor-go --replicas=2 -n weather-system

# Escalar Valkey
kubectl scale deployment valkey --replicas=3 -n weather-system
```

## 9. Respuestas a Preguntas Técnicas

### 9.1 ¿Por qué usar Kafka vs RabbitMQ?

**Kafka**:
- ✅ Mejor para alto volumen y velocidad
- ✅ Persistencia de eventos
- ✅ Replay de mensajes
- ❌ Mayor complejidad operativa

**RabbitMQ**:
- ✅ Más simple de configurar
- ✅ Enrutamiento flexible
- ✅ Confirmaciones de entrega
- ❌ Menor throughput en carga masiva

### 9.2 ¿Por qué usar Valkey en lugar de Redis?

- Valkey es un fork activo de Redis
- Mejor soporte para open source
- Licencia más permisiva
- Rendimiento equivalente o superior

### 9.3 ¿Por qué gRPC para comunicación interna?

- Mayor rendimiento que HTTP/REST
- Serialización binaria (Protocol Buffers)
- Soporte nativo para streaming
- Mejor uso de ancho de banda

### 9.4 Impacto del replicado en Valkey

Con 2 réplicas:
- ✅ Alta disponibilidad
- ✅ Persistencia de datos
- ❌ Duplicación de recursos
- ❌ Ligeramente mayor latencia de escritura

### 9.5 Ventajas de HPA

- Auto-escalado automático según demanda
- Reducción de costos al escalar hacia abajo
- Mejor aprovechamiento de recursos
- Respuesta rápida a picos de carga

## 10. Conclusiones

Este sistema demuestra:
1. ✅ Arquitectura distribuida y escalable
2. ✅ Uso eficiente de tecnologías modernas
3. ✅ Alta concurrencia con Rust y Go
4. ✅ Procesamiento de eventos en tiempo real
5. ✅ Orquestación automática con Kubernetes
6. ✅ Comparativa de tecnologías de mensajería
7. ✅ Visualización en tiempo real con Grafana

## 11. Comandos Útiles

```bash
# Verificar estado general
kubectl get all -n weather-system

# Ver logs de un pod
kubectl logs -f deployment/weather-api-rust -n weather-system

# Port-forward a Grafana
kubectl port-forward -n weather-system svc/grafana 3000:80

# Port-forward a RabbitMQ Management
kubectl port-forward -n weather-system svc/rabbitmq 15672:15672

# Verificar HPA
kubectl get hpa -n weather-system

# Aplicar cambios
kubectl apply -f k8s/

# Eliminar todo
kubectl delete namespace weather-system
```

---

**Fecha**: Octubre 2025
**Estudiante**: Luis Pablo García (202200129)
