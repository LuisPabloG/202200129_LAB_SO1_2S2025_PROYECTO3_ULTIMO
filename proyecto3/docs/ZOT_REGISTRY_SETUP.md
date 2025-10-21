# Configuración de Zot Registry

## ¿Qué es Zot?

Zot es un Container Registry de código abierto compatible con OCI, diseñado para ser simple, seguro y eficiente. Es perfecto para proyectos en Kubernetes.

## Instalación de Zot en GCP VM

### 1. Crear una VM en GCP

```bash
gcloud compute instances create zot-registry \
  --zone=us-central1-c \
  --machine-type=e2-medium \
  --image-family=debian-12 \
  --image-project=debian-cloud \
  --scopes=default \
  --metadata-from-file startup-script=- << 'EOF'
#!/bin/bash

# Actualizar sistema
apt-get update
apt-get install -y docker.io wget

# Descargar Zot
mkdir -p /etc/zot
cd /tmp
wget https://github.com/project-zot/zot/releases/download/v2.0.0/zot-linux-amd64
chmod +x zot-linux-amd64
mv zot-linux-amd64 /usr/local/bin/zot

# Crear configuración de Zot
cat > /etc/zot/config.json << 'CONFIG'
{
  "http": {
    "address": "0.0.0.0",
    "port": "5000"
  },
  "storage": {
    "rootDirectory": "/var/lib/zot"
  },
  "log": {
    "level": "debug"
  }
}
CONFIG

# Crear directorio de almacenamiento
mkdir -p /var/lib/zot

# Crear servicio systemd
cat > /etc/systemd/system/zot.service << 'SERVICE'
[Unit]
Description=Zot Registry
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/zot serve /etc/zot/config.json
Restart=always
User=root

[Install]
WantedBy=multi-user.target
SERVICE

# Habilitar y iniciar Zot
systemctl daemon-reload
systemctl enable zot
systemctl start zot

# Permitir puerto 5000
ufw allow 5000/tcp || true
EOF
```

### 2. Obtener IP de la VM

```bash
gcloud compute instances list --filter="name:zot-registry" --format="value(EXTERNAL_IP)"
```

## Usar Zot en el Proyecto

### 1. Configurar Docker para usar Zot

```bash
# En tu máquina local, agregar Zot como registry inseguro
cat > /etc/docker/daemon.json << EOF
{
  "insecure-registries": ["ZOT_IP:5000"]
}
EOF

# Reiniciar Docker
systemctl restart docker
```

### 2. Construir y subir imágenes

```bash
ZOT_IP="tu-zot-ip"
ZOT_REGISTRY="$ZOT_IP:5000"

# Construir imágenes
cd proyecto3
docker build -f docker/Dockerfile.rust -t $ZOT_REGISTRY/weather-api-rust:latest .
docker build -f docker/Dockerfile.go -t $ZOT_REGISTRY/weather-processor-go:latest .
docker build -f docker/Dockerfile.locust -t $ZOT_REGISTRY/locust-load-test:latest .

# Subir imágenes
docker push $ZOT_REGISTRY/weather-api-rust:latest
docker push $ZOT_REGISTRY/weather-processor-go:latest
docker push $ZOT_REGISTRY/locust-load-test:latest
```

### 3. Actualizar manifiestos de Kubernetes

```bash
# Reemplazar registry en todos los archivos
sed -i "s|docker.io|$ZOT_IP:5000|g" proyecto3/k8s/deployments/*.yaml
sed -i 's|imagePullPolicy: IfNotPresent|imagePullPolicy: Always|g' proyecto3/k8s/deployments/*.yaml
```

### 4. Crear imagePullSecret en Kubernetes (si es necesario)

```bash
kubectl create secret docker-registry zot-secret \
  --docker-server=$ZOT_IP:5000 \
  --docker-username=tu-usuario \
  --docker-password=tu-contraseña \
  --docker-email=tu-email@example.com \
  -n weather-system

# Agregar el secret a los deployments:
# spec:
#   imagePullSecrets:
#   - name: zot-secret
```

## Descargar OCI Artifacts desde Zot

### 1. Usar `zot` CLI para descargar

```bash
# Descargar un artifact
zot blob download $ZOT_REGISTRY/weather-api-rust latest-config.json
```

### 2. Usar `skopeo` para descargar imágenes

```bash
# Descargar imagen completa
skopeo copy --insecure-policy docker://$ZOT_REGISTRY/weather-api-rust:latest oci:/tmp/weather-api
```

## Verificar Zot Registry

```bash
# Acceder a la interfaz web
# http://ZOT_IP:5000

# O usar curl para verificar
curl -u usuario:contraseña http://ZOT_IP:5000/v2/_catalog

# Ver repositorios
curl -u usuario:contraseña http://ZOT_IP:5000/v2/weather-api-rust/tags/list
```

## Limpiar Zot

```bash
# Eliminar una imagen
curl -X DELETE http://ZOT_IP:5000/v2/weather-api-rust/manifests/sha256:<digest>

# Ver todos los repositorios
curl http://ZOT_IP:5000/v2/_catalog
```

---

**Nota**: Reemplaza `ZOT_IP` con la IP externa de tu VM de Zot.
