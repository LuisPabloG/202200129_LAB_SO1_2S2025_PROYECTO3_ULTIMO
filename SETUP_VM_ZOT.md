# Guía para Crear VM con Zot en GCP

## Paso 1: Crear la VM en GCP (Google Cloud Console)

```bash
# Opción 1: Desde Cloud Console
# 1. Ve a "Compute Engine" > "Instances"
# 2. Click "CREATE INSTANCE"
# 3. Configura:
#    - Name: zot-registry
#    - Region: us-central1
#    - Zone: us-central1-c (igual a tu cluster)
#    - Machine type: e2-medium (mínimo recomendado)
#    - Boot disk: Ubuntu 20.04 LTS, 30GB
#    - Allow HTTP traffic: ✓
#    - Allow HTTPS traffic: ✓
# 4. Click "CREATE"
```

## Paso 2: Conectarse a la VM y Instalar Docker + Zot

```bash
# Conectarse a la VM (desde Cloud Shell o SSH)
gcloud compute ssh zot-registry --zone us-central1-c

# Una vez dentro de la VM, ejecutar:

# Actualizar paquetes
sudo apt-get update
sudo apt-get upgrade -y

# Instalar Docker
sudo apt-get install -y docker.io

# Iniciar Docker
sudo systemctl start docker
sudo usermod -aG docker $USER
newgrp docker

# Crear directorio para Zot
mkdir -p ~/zot-data

# Descargar imagen de Zot
docker pull ghcr.io/project-zot/zot:latest

# Crear archivo de configuración para Zot
mkdir -p ~/zot-config
cat > ~/zot-config/config.json << 'EOF'
{
  "distSpecVersion": "1.0.0",
  "storage": {
    "rootDirectory": "/var/lib/zot"
  },
  "http": {
    "address": "0.0.0.0",
    "port": 5000
  },
  "log": {
    "level": "info"
  }
}
EOF

# Ejecutar Zot en Docker
docker run -d \
  --name zot-registry \
  -p 5000:5000 \
  -v ~/zot-data:/var/lib/zot \
  -v ~/zot-config:/etc/zot \
  ghcr.io/project-zot/zot:latest /etc/zot/config.json

# Verificar que Zot está corriendo
docker ps | grep zot

# Obtener la IP externa de la VM
gcloud compute instances describe zot-registry --zone us-central1-c --format='get(networkInterfaces[0].accessConfigs[0].natIP)'
```

## Paso 3: Verificar Zot

```bash
# Desde Cloud Shell, obtener IP de la VM
VM_IP=$(gcloud compute instances describe zot-registry --zone us-central1-c --format='get(networkInterfaces[0].accessConfigs[0].natIP)')

# Verificar acceso a Zot (debería responder con estado 200)
curl -I http://$VM_IP:5000/v2/

# Guardá esta IP para usarla en los deployments de Kubernetes
echo "Tu URL de Zot es: http://$VM_IP:5000"
```

## Paso 4: Configurar Firewall (si es necesario)

```bash
# Permitir tráfico HTTP en puerto 5000
gcloud compute firewall-rules create allow-zot \
  --allow=tcp:5000 \
  --source-ranges=0.0.0.0/0 \
  --description="Allow Zot registry access"
```

## Notas Importantes

- Reemplaza `[YOUR-VM-IP]` con la IP real que obtuviste
- Asegúrate de que el cluster de Kubernetes esté en la misma zona (`us-central1-c`)
- Guarda la IP de la VM para usarla en los Dockerfiles y YAMLs
