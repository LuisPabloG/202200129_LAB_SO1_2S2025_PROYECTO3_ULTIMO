# 🌦️ Proyecto 3: Weather Tweets System - GUÍA RÁPIDA

## 📋 Información del Estudiante
- **Carnet**: 202200129
- **Municipio**: Chinautla
- **Cluster GKE**: sopes1 (34.135.121.113)
- **Fecha**: Octubre 2025

## 🚀 Resumen Rápido

Este proyecto implementa un sistema distribuido de procesamiento de tweets meteorológicos utilizando Kubernetes en GCP.

### ✅ Lo que ya está hecho:

1. **Estructura completa del proyecto** ✓
   - Src: Código Rust y Go
   - Docker: Dockerfiles para todos los componentes
   - K8s: Manifiestos de Kubernetes
   - Scripts: Automatización y tests

2. **Conexión a GKE** ✓
   - Cluster sopes1 accesible
   - Kubeconfig configurado
   - Namespace weather-system creado

3. **Documentación técnica completa** ✓
   - README.md con arquitectura detallada
   - Especificaciones de componentes
   - Guías de deployment

### ⏳ Próximos pasos (a implementar):

1. **Construir imágenes Docker**
   - API Rust → weather-api-rust:latest
   - Go Processor → weather-processor-go:latest
   - Go Consumers → kafka-consumer-go:latest, rabbitmq-consumer-go:latest
   - Locust → weather-locust:latest

2. **Configurar Zot Registry en VM**
   - Crear VM en GCP
   - Instalar Zot
   - Publicar imágenes

3. **Desplegar Infrastructure**
   - NGINX Ingress Controller
   - Strimzi Kafka
   - RabbitMQ
   - Grafana

4. **Completar código**
   - Rust API REST completa
   - Go gRPC services
   - Consumers con persistencia en Valkey

5. **Testing y validación**
   - Ejecutar Locust con 10,000 peticiones
   - Validar flujo de datos
   - Medir rendimiento

## 📁 Estructura del Proyecto

```
proyecto3/
├── src/
│   ├── rust/              # API REST (Actix-web)
│   │   ├── Cargo.toml
│   │   └── src/main.rs
│   ├── go/                # Servicios gRPC
│   │   ├── go.mod
│   │   ├── api/processor.go
│   │   ├── grpc_server/
│   │   └── consumer/
│   └── weathertweet.proto # Definición gRPC
├── docker/
│   ├── Dockerfile.rust
│   ├── Dockerfile.go
│   └── Dockerfile.locust
├── k8s/
│   ├── namespaces/        # Namespace weather-system
│   ├── deployments/       # Todos los servicios
│   ├── services/          # ClusterIP services
│   ├── ingress/           # NGINX Ingress
│   └── hpa/               # Horizontal Pod Autoscaler
├── scripts/
│   ├── locustfile.py      # Tests de carga
│   ├── deploy-all.sh      # Deployment completo
│   └── simple-deploy.sh   # Deployment simplificado
└── docs/
    └── README.md          # Documentación técnica
```

## 🔧 Comandos Útiles

### Conexión al Cluster
```bash
export KUBECONFIG=~/.kube/config-simple
kubectl cluster-info
kubectl get namespaces
```

### Ver Estado
```bash
kubectl get all -n weather-system
kubectl get pods -n weather-system
kubectl logs deployment/weather-api-rust -n weather-system
```

### Port Forwarding
```bash
# Grafana
kubectl port-forward -n weather-system svc/grafana 3000:80

# RabbitMQ Management
kubectl port-forward -n weather-system svc/rabbitmq 15672:15672

# Valkey
kubectl port-forward -n weather-system svc/valkey-service 6379:6379
```

### Scaling
```bash
# Escalar manualmente
kubectl scale deployment weather-api-rust --replicas=3 -n weather-system

# Ver HPA
kubectl get hpa -n weather-system
kubectl describe hpa weather-api-rust-hpa -n weather-system
```

### Troubleshooting
```bash
# Ver descripción detallada
kubectl describe pod <pod-name> -n weather-system

# Ver eventos
kubectl get events -n weather-system --sort-by='.lastTimestamp'

# Ver logs
kubectl logs -f <pod-name> -n weather-system
```

## 📊 Flujo de Datos

```
┌─────────────────────┐
│   Locust (Python)   │ ← Genera carga de 10,000 peticiones
└──────────┬──────────┘
           │ POST /weather
           ▼
┌─────────────────────┐
│  NGINX Ingress      │ ← Enruta el tráfico
└──────────┬──────────┘
           │ 8080
           ▼
┌─────────────────────┐
│  Rust API REST      │ ← Recibe tweets
│  (1-3 replicas)     │ ← Escalable con HPA
└──────────┬──────────┘
           │ gRPC :50051
           ▼
┌─────────────────────┐
│  Go Processor       │ ← Procesa tweets
│  (gRPC Server)      │
└────┬────────┬───────┘
     │        │
  Kafka   RabbitMQ
     │        │
     ▼        ▼
┌──────┐  ┌──────────┐
│Kafka │  │RabbitMQ  │
│      │  │ (1-2 reps)
└──┬───┘  └─────┬────┘
   │            │
   ▼            ▼
┌─────────────────────┐
│ Go Consumers        │
│ Kafka + RabbitMQ    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Valkey (2 reps)    │ ← Persistencia
│  (Base en memoria)  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│     Grafana         │ ← Visualización
│   Dashboard Real    │   Time
└─────────────────────┘
```

## 🎯 Especificación del Tweet

```json
{
  "municipality": 4,     // Chinautla
  "temperature": 25,     // Celsius
  "humidity": 65,        // Porcentaje
  "weather": 2           // cloudy (1=sunny, 2=cloudy, 3=rainy, 4=foggy)
}
```

## 🏗️ Tecnologías

| Componente | Tecnología | Propósito |
|-----------|-----------|---------|
| API | Rust + Actix-web | REST, alta concurrencia |
| Servicios | Go + gRPC | Procesamiento distribuido |
| Message Broker | Kafka (Strimzi) | Eventos de alto volumen |
| Message Broker | RabbitMQ | Alternativa tradicional |
| BD Memoria | Valkey | Almacenamiento rápido |
| Orquestación | Kubernetes (GKE) | Gestión de contenedores |
| Ingress | NGINX | Enrutamiento HTTP |
| Visualización | Grafana | Dashboards |
| Testing | Locust | Carga masiva |

## 📈 Métricas Clave

El sistema debe medir:
- **Throughput**: Peticiones/segundo
- **Latencia**: Tiempo de respuesta
- **Escalabilidad**: Comportamiento con 1, 2, 3 réplicas
- **Persistencia**: Datos en Valkey
- **Disponibilidad**: Uptime del sistema

## 🔐 Seguridad

- Namespace dedicado (weather-system)
- Resource limits configurados
- Ingress con HTTPS (opcional para producción)
- Control de acceso RBAC (opcional)

## 📞 Contacto & Soporte

- **Email**: lpvvs2013@gmail.com
- **GitHub**: Repositorio privado
- **GCP Project**: proyecto-3-475405
- **Cluster**: sopes1

---

**Estado**: ✅ Estructura lista, implementación en progreso
**Última actualización**: Octubre 21, 2025
