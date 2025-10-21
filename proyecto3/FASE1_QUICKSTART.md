# FASE 1: Quick Start Guide

## 🎯 Objetivo
Configurar los componentes base del Proyecto 3 e implementar la primera fase: **Configuración y Componentes Base**

## 📋 Lo que se ha completado

### ✅ FASE 1.1 - Estructura del Repositorio
- [x] Carpeta `proyecto3/` creada con estructura base
- [x] README con descripción completa del proyecto
- [x] Directorio `proto/` con archivo `weather_tweet.proto` para gRPC
- [x] Directorios para cada componente: `rust-api/`, `go-deployment-1/`, `go-writers/`, `go-consumers/`, `locust/`, `kubernetes/`

### ✅ FASE 1.2 - Verificación del Cluster GKE
- [x] Cluster GKE `sopes1` verificado y funcionando
- [x] 3 nodos en la zona `us-central1-c`
- [x] NGINX Ingress Controller instalado (IP: 35.238.126.87)
- [x] Namespaces creados: `weather-system`, `kafka`, `rabbitmq`

### ✅ FASE 1.3 - API REST en Rust
- [x] Proyecto Rust creado con `Cargo.toml`
- [x] Endpoints implementados:
  - `POST /api/weather` - Recibir tweets del clima
  - `GET /api/weather` - Obtener todos los tweets
  - `GET /health` - Health check
  - `GET /ready` - Readiness check
  - `GET /` - Info del servicio
- [x] Dockerfile multi-stage optimizado
- [x] Soporta escalamiento automático (HPA)

### ✅ FASE 1.4 - Go Deployment 1 (gRPC Client)
- [x] Servicio Go creado como receptor de Rust API
- [x] Endpoints implementados:
  - `POST /api/weather` - Recibir tweets
  - `GET /stats` - Estadísticas
  - `GET /health` - Health check
  - `GET /ready` - Readiness check
- [x] Dockerfile optimizado para Alpine Linux
- [x] Manejo de concurrencia con Go

### ✅ FASE 1.5 - Locust Load Generator
- [x] Script `locustfile.py` creado
- [x] Generador de tweets para municipio asignado: **Chinautla**
- [x] Estructura de datos correcta: `{municipality, temperature, humidity, weather}`
- [x] Configuración: 10,000 peticiones, 10 usuarios concurrentes

### ✅ FASE 1.6 - Manifiestos de Kubernetes
- [x] `00-namespaces.yaml` - Namespaces del proyecto
- [x] `01-rust-api-deployment.yaml` - Deployment de Rust API con Service
- [x] `02-go-deployment-1.yaml` - Deployment de Go Client con Service
- [x] `03-ingress.yaml` - Ingress controller configuration

### ✅ FASE 1.7 - Scripts de Automatización
- [x] `build-images.sh` - Construir imágenes Docker localmente
- [x] `push-to-zot.sh` - Empujar imágenes a Zot Registry
- [x] `deploy-phase1.sh` - Desplegar Fase 1 en GKE
- [x] `deploy-quick.sh` - Despliegue rápido de prueba

## 🚀 Pasos para Desplegar

### Paso 1: Configurar acceso al cluster
```bash
export KUBECONFIG=~/.kube/config-sopes1
source ~/kube-setup.sh
```

### Paso 2: Construir imágenes Docker
```bash
cd proyecto3
./build-images.sh
```

### Paso 3: Empujar imágenes a Zot (si tienes Zot configurado)
```bash
./push-to-zot.sh <REGISTRY_URL> [usuario] [contraseña]
```

Ejemplo con Zot local:
```bash
./push-to-zot.sh localhost:5000
```

### Paso 4: Desplegar en GKE
```bash
./deploy-phase1.sh
```

O rápidamente con:
```bash
./deploy-quick.sh
```

## 📊 Verificar el Despliegue

```bash
# Ver estado de los pods
export KUBECONFIG=~/.kube/config-sopes1
kubectl get pods -n weather-system -o wide

# Ver servicios
kubectl get svc -n weather-system

# Ver ingress
kubectl get ingress -n weather-system

# Ver logs del Rust API
kubectl logs -n weather-system deployment/rust-api -f

# Ver logs del Go Client
kubectl logs -n weather-system deployment/go-deployment-1 -f
```

## 🧪 Probar los Endpoints

Con Ingress IP: `35.238.126.87`

```bash
# Health check
curl http://35.238.126.87/health

# Info del servicio
curl http://35.238.126.87/

# Enviar un tweet
curl -X POST http://35.238.126.87/api/weather \
  -H "Content-Type: application/json" \
  -d '{
    "municipality": "chinautla",
    "temperature": 25,
    "humidity": 65,
    "weather": "cloudy"
  }'

# Ver tweets en Rust API
curl http://35.238.126.87/api/weather

# Ver estadísticas en Go Client
curl http://35.238.126.87/stats
```

## 🧬 Estructura de Tweet

```json
{
  "municipality": "chinautla",
  "temperature": 25,
  "humidity": 65,
  "weather": "cloudy"
}
```

**Municipio asignado**: Chinautla (carnet 202200129, último dígito 9)
**Temperaturas**: 15°C a 35°C
**Humedad**: 30% a 90%
**Climas**: sunny, cloudy, rainy, foggy

## ⚙️ Configuración del Sistema

| Componente | Puerto | Namespace | Replicas | CPU | Memoria |
|-----------|--------|-----------|----------|-----|---------|
| Rust API | 8080 | weather-system | 1 (HPA: 1-3) | 100m-500m | 128Mi-512Mi |
| Go Client | 8081 | weather-system | 1 | 50m-200m | 64Mi-256Mi |
| Ingress | 80/443 | ingress-nginx | - | - | - |

## 📝 Próximos Pasos (FASE 2-5)

- **FASE 2**: Desplegar Kafka y RabbitMQ, crear Writers
- **FASE 3**: Crear Consumidores y desplegar Valkey
- **FASE 4**: Desplegar Grafana, configurar HPA, pruebas de carga
- **FASE 5**: Documentación técnica final

## 🔧 Troubleshooting

### El Ingress IP sigue en PENDING
```bash
kubectl get svc -n ingress-nginx
# Espera 2-3 minutos para que GCP asigne la IP externa
```

### Los pods no inician
```bash
kubectl describe pod <pod-name> -n weather-system
kubectl logs <pod-name> -n weather-system
```

### Las imágenes de Docker no construyen
```bash
# Verificar que Docker está corriendo
docker ps

# Verificar dependencias
cargo --version  # Para Rust
go version       # Para Go
```

## 📞 Información del Proyecto

- **Carnet**: 202200129
- **Municipio**: Chinautla
- **Proyecto**: Tweets del Clima - Arquitectura Distribuida en Kubernetes
- **Cluster**: proyecto-3-475405 / sopes1 (us-central1-c)
- **Ingress IP**: 35.238.126.87

---
**Estado**: FASE 1 Completada ✅
**Fecha**: 21 de octubre de 2025
