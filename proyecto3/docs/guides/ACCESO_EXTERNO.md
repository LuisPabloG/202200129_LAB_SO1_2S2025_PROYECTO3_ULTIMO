# 🌐 ACCESO EXTERNO - Proyecto 3 SOPES1

## ✅ IPs EXTERNAS ACTIVAS

### 1️⃣ **Go Deployment 1 API** (Receptor de tweets)
```
URL: http://34.70.218.90:80
```

**Endpoints disponibles:**
- `POST   http://34.70.218.90/api/weather`    → Enviar tweet
- `GET    http://34.70.218.90/stats`          → Ver estadísticas
- `GET    http://34.70.218.90/health`         → Health check
- `GET    http://34.70.218.90/`               → Info del servicio

**Ejemplo de request POST:**
```bash
curl -X POST http://34.70.218.90/api/weather \
  -H "Content-Type: application/json" \
  -d '{
    "municipality": "chinautla",
    "temperature": 28,
    "humidity": 65,
    "weather": "sunny"
  }'
```

**Ejemplo de request GET:**
```bash
curl http://34.70.218.90/stats | jq .
```

---

### 2️⃣ **Grafana Dashboard** (Visualización)
```
URL: http://136.112.59.160:80
```

**Credenciales:**
- Usuario: `admin`
- Contraseña: `admin`

**Lo que verás:**
- Dashboard vacío (listo para cargar datos)
- Opción para agregar Data Source (Valkey)
- Panels para mostrar tweets en tiempo real

---

## 🔧 Zot Container Registry

Debido a limitaciones de recursos en el cluster de GKE actual, implementaremos Zot de dos formas:

### Opción A: Usar Google Container Registry (GCR) - YA CONFIGURADO ✅

Ya estamos usando: `gcr.io/proyecto-3-475405`

**Comandos para trabajar con GCR:**

```bash
# Autenticarse con GCR
gcloud auth configure-docker

# Etiquetar imagen
docker tag my-image gcr.io/proyecto-3-475405/my-image:v1

# Empujar imagen
docker push gcr.io/proyecto-3-475405/my-image:v1

# Tirar imagen
docker pull gcr.io/proyecto-3-475405/my-image:v1
```

### Opción B: Desplegar Zot en VM externa (Recomendado para producción)

Para crear un Zot Registry externo en una VM de GCP:

```bash
# 1. Crear VM en GCP
gcloud compute instances create zot-registry \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --zone=us-central1-c \
  --machine-type=e2-medium \
  --scopes=https://www.googleapis.com/auth/cloud-platform

# 2. SSH a la VM
gcloud compute ssh zot-registry --zone=us-central1-c

# 3. En la VM, instalar Docker
sudo apt update && sudo apt install -y docker.io

# 4. Descargar y ejecutar Zot
docker pull ghcr.io/project-zot/zot-linux-amd64:latest
docker run -d \
  -p 5000:5000 \
  -v /data/zot:/var/lib/zot \
  --name zot \
  ghcr.io/project-zot/zot-linux-amd64:latest

# 5. Obtener IP externa de la VM
gcloud compute instances describe zot-registry --zone=us-central1-c --format='value(networkInterfaces[0].accessConfigs[0].natIP)'
```

**Luego usar Zot desde tu máquina:**
```bash
docker tag my-image <ZOT-IP>:5000/my-image:v1
docker push <ZOT-IP>:5000/my-image:v1
```

---

## 📋 RESUMEN DE ACCESOS

| Servicio | URL Externa | Puerto | Tipo |
|----------|------------|--------|------|
| **Go API** | `http://34.70.218.90` | 80 | LoadBalancer |
| **Grafana** | `http://136.112.59.160` | 80 | LoadBalancer |
| **GCR Registry** | `gcr.io/proyecto-3-475405` | N/A | Google Cloud |
| **Zot (Ext)** | A configurar en VM | 5000 | Externo |

---

## 🧪 TEST DESDE MÁQUINA LOCAL

Abre tu navegador y prueba:

**1. Ver API en vivo:**
```
http://34.70.218.90
```

**2. Ver estadísticas:**
```
http://34.70.218.90/stats
```

**3. Acceder a Grafana:**
```
http://136.112.59.160
```

---

## ⚙️ COMANDOS PARA VERIFICAR

```bash
# Ver servicios LoadBalancer
export KUBECONFIG=~/.kube/config-gke
kubectl get svc -n weather-system -o wide

# Ver pods corriendo
kubectl get pods -n weather-system

# Ver logs del Go service
kubectl logs -f deployment/go-deployment-1 -n weather-system

# Port-forward local (si necesitas acceso local)
kubectl port-forward svc/go-deployment-1-service 8081:8081 -n weather-system
kubectl port-forward svc/grafana 3000:80 -n weather-system
```

---

## 📝 NOTAS IMPORTANTES

- ✅ Las IPs externas están **ACTIVAS AHORA**
- ✅ El servicio Go almacena datos en Valkey en tiempo real
- ⏳ Grafana necesita Data Source configurado (Valkey)
- 🔄 Las IPs pueden cambiar si los servicios se reinician (son dinámicas)

---

**Última actualización**: 21 de octubre de 2025, 17:15
