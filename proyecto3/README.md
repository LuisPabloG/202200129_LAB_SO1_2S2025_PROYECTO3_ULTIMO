# Proyecto 3: Tweets del Clima - Arquitectura Distribuida en Kubernetes

**Carnet:** 202200129  
**Municipio Asignado:** Chinautla (último dígito: 9)  
**Curso:** Sistemas Operativos 1  
**Institución:** Universidad San Carlos de Guatemala

## 📋 Descripción del Proyecto

Sistema distribuido y escalable para simular la recepción y procesamiento de "tweets" sobre el clima local usando Google Kubernetes Engine (GKE). El proyecto implementa una arquitectura de microservicios completa con:

- **Generación de carga:** Locust
- **API REST:** Rust (con escalado automático HPA)
- **Servicios de procesamiento:** Go (gRPC)
- **Message Brokers:** Kafka y RabbitMQ
- **Almacenamiento en memoria:** Valkey
- **Visualización:** Grafana
- **Container Registry:** Zot
- **Orquestación:** Kubernetes (GKE)

## 🏗️ Estructura del Proyecto

```
proyecto3/
├── proto/                    # Archivos .proto para gRPC
│   └── weather_tweet.proto
├── rust-api/                # API REST en Rust
│   ├── src/
│   ├── Cargo.toml
│   └── Dockerfile
├── go-deployment-1/         # Deployment 1: gRPC Client
│   ├── main.go
│   ├── go.mod
│   └── Dockerfile
├── go-writers/              # Deployments 2 y 3: Writers para Kafka y RabbitMQ
│   ├── kafka-writer/
│   ├── rabbitmq-writer/
│   ├── go.mod
│   └── Dockerfile
├── go-consumers/            # Consumidores para Kafka y RabbitMQ
│   ├── kafka-consumer/
│   ├── rabbitmq-consumer/
│   ├── go.mod
│   └── Dockerfile
├── locust/                  # Scripts de carga
│   ├── locustfile.py
│   └── Dockerfile
├── kubernetes/              # Manifiestos de Kubernetes
│   ├── namespaces.yaml
│   ├── ingress-nginx.yaml
│   ├── rust-api-deployment.yaml
│   ├── go-deployment-1.yaml
│   ├── kafka-deployment.yaml
│   ├── rabbitmq-deployment.yaml
│   ├── valkey-deployment.yaml
│   ├── grafana-deployment.yaml
│   └── hpa.yaml
└── docs/                    # Documentación técnica
    └── INFORME_TECNICO.md
```

## 🚀 Inicio Rápido

### Requisitos Previos

- GCP Account with GKE cluster (`sopes1`)
- `gcloud` CLI configurado
- `kubectl` instalado
- Docker instalado localmente
- Rust, Go, Python instalados

### Fase 1: Configuración y Componentes Base

1. **Configurar acceso al cluster:**
   ```bash
   gcloud container clusters get-credentials sopes1 --zone us-central1-c --project proyecto-3-475405
   ```

2. **Crear namespaces:**
   ```bash
   kubectl create namespace weather-system
   kubectl create namespace kafka
   kubectl create namespace rabbitmq
   ```

3. **Instalar NGINX Ingress Controller:**
   ```bash
   helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
   helm install nginx-ingress ingress-nginx/ingress-nginx --namespace ingress-nginx --create-namespace
   ```

4. **Desplegar componentes base:**
   ```bash
   kubectl apply -f kubernetes/namespaces.yaml
   kubectl apply -f kubernetes/rust-api-deployment.yaml
   kubectl apply -f kubernetes/go-deployment-1.yaml
   ```

## 📊 Componentes Clave

### 1. API REST en Rust
- Puerto: 8080
- Recibe peticiones HTTP con estructura JSON
- Escalable automáticamente (HPA: 1-3 réplicas basadas en CPU > 30%)

### 2. Servicios gRPC en Go
- **Deployment 1:** Cliente gRPC que recibe de Rust
- **Deployment 2:** gRPC Server para Kafka Writer
- **Deployment 3:** gRPC Server para RabbitMQ Writer

### 3. Message Brokers
- **Kafka:** Usando Strimzi Operator
- **RabbitMQ:** Deployment estándar

### 4. Almacenamiento
- **Valkey:** BD en memoria con persistencia (2 réplicas)

### 5. Visualización
- **Grafana:** Dashboard para visualizar datos de Valkey

## 📈 Pruebas de Carga

Locust genera peticiones simulando tweets del clima de Chinautla:

```json
{
  "municipality": "chinautla",
  "temperature": 25,
  "humidity": 65,
  "weather": "cloudy"
}
```

**Configuración de prueba:**
- 10,000 peticiones
- 10 usuarios concurrentes

## 📝 Documentación

Ver archivo detallado: [`docs/INFORME_TECNICO.md`](./docs/INFORME_TECNICO.md)

## 🔗 Enlaces Útiles

- [Proyecto de GCP](https://console.cloud.google.com/kubernetes/clusters?project=proyecto-3-475405)
- [Especificación del Proyecto](../proyecto3_md/Proyecto3-SOPES1-kubernetes-Enunciado.md)
- [Documentación Kubernetes](https://kubernetes.io/docs/)
- [Documentación Rust](https://www.rust-lang.org/learn)
- [Documentación Go](https://golang.org/doc/)

## 📅 Cronograma

| Fase | Descripción | Duración |
|------|-------------|----------|
| 1 | Configuración y Componentes Base | Semana 1 |
| 2 | Message Brokers y Writers | Semana 2 |
| 3 | Consumidores y Valkey | Semana 2 |
| 4 | Grafana, HPA y Pruebas | Semana 3 |
| 5 | Documentación Final | Semana 4 |

**Fecha de Entrega:** 25 de octubre de 2025

## ✅ Requisitos de Calificación

- [ ] Cluster GKE funcionando
- [ ] Zot Registry configurado
- [ ] API REST en Rust implementada y escalable
- [ ] Servicios gRPC en Go funcionando
- [ ] Message Brokers (Kafka y RabbitMQ) desplegados
- [ ] Consumidores almacenando en Valkey
- [ ] Grafana mostrando dashboard
- [ ] HPA para Rust API funcionando
- [ ] Pruebas de carga completadas
- [ ] Documentación técnica completa

## 📧 Contacto

**Estudiante:** Luis Pablo Garcia  
**Carnet:** 202200129  
**Email:** [tu-email@email.com]

---

**Última actualización:** 21 de octubre de 2025
