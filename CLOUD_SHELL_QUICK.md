# 🚀 GUÍA RÁPIDA: Ejecutar en Cloud Shell

## Opción 1: Todo Automático (RECOMENDADO)

Copia y pega esto en tu Cloud Shell y presiona Enter:

```bash
# ============================================
# BLOQUE COMPLETO - Copiar y pegar todo junto
# ============================================

PROJECT_ID="proyecto-3-475405"
CLUSTER_NAME="sopes1"
ZONE="us-central1-c"
NAMESPACE="weather-tweets"

# 1. Configurar gcloud
gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE

# 2. Obtener credenciales
gcloud container clusters get-credentials $CLUSTER_NAME --zone $ZONE --project $PROJECT_ID

# 3. Verificar conexión
echo "✓ Verificando cluster..."
kubectl cluster-info

# 4. Crear Storage Class
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
allowVolumeExpansion: true
EOF

# 5. Instalar NGINX Ingress Controller
echo "✓ Instalando NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# 6. Esperar a NGINX
echo "✓ Esperando que NGINX esté listo (máximo 5 min)..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s

# 7. Crear namespace
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# 8. Obtener IP del Ingress
echo ""
echo "==============================================="
echo "✓ Obteniendo IP externa del Ingress..."
echo "==============================================="
sleep 10

for i in {1..36}; do
    INGRESS_IP=$(kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx \
      -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
    if [ -n "$INGRESS_IP" ]; then
        echo ""
        echo "✓✓✓ IP DEL INGRESS: $INGRESS_IP ✓✓✓"
        echo ""
        break
    fi
    echo -n "."
    sleep 5
done

# 9. Mostrar status
echo ""
echo "==============================================="
echo "Status del Cluster"
echo "==============================================="
kubectl get nodes
echo ""
kubectl get namespaces
echo ""
echo "==============================================="
echo "✓ CONFIGURACIÓN COMPLETADA"
echo "==============================================="
echo ""
echo "Próximo paso: Clonar repositorio y desplegar"
echo ""
```

---

## Opción 2: Paso a Paso (si prefieres ir lento)

### Paso 1: Configurar gcloud

```bash
gcloud config set project proyecto-3-475405
gcloud config set compute/zone us-central1-c
```

### Paso 2: Obtener credenciales del cluster

```bash
gcloud container clusters get-credentials sopes1 --zone us-central1-c --project proyecto-3-475405
```

### Paso 3: Verificar conexión

```bash
kubectl cluster-info
kubectl get nodes
```

### Paso 4: Crear Storage Class

```bash
kubectl apply -f - <<'EOF'
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: standard
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
allowVolumeExpansion: true
EOF
```

### Paso 5: Instalar NGINX Ingress Controller

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml

# Esperar a que esté listo (máximo 5 minutos)
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=300s
```

### Paso 6: Crear namespace

```bash
kubectl create namespace weather-tweets --dry-run=client -o yaml | kubectl apply -f -
```

### Paso 7: Obtener IP del Ingress

```bash
# Esperar 10 segundos
sleep 10

# Obtener IP
kubectl get svc -n ingress-nginx nginx-ingress-ingress-nginx \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Esto debería mostrarte una IP como: 34.xxx.xxx.xxx
```

---

## Paso 8: Clonar y Desplegar

Una vez completados los pasos anteriores:

```bash
# Clonar repositorio
git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO.git

# Navegar
cd 202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3

# Desplegar TODO
bash scripts/quick-deploy.sh
```

---

## ⚠️ Si algo no funciona

### Error: gke-gcloud-auth-plugin not found

Simplemente ignóralo. El comando seguirá funcionando.

### No puedo conectarme al cluster

Verifica que estés en Cloud Shell y ejecuta:

```bash
gcloud config list
# Debe mostrar proyecto-3-475405
```

### NGINX Ingress no obtiene IP

Es normal que tarde. Espera 2-3 minutos más y ejecuta:

```bash
kubectl get svc -n ingress-nginx
# La IP debería aparecer en "EXTERNAL-IP"
```

### Ver logs para debugging

```bash
# Ver eventos
kubectl get events -n ingress-nginx

# Ver pods de NGINX
kubectl get pods -n ingress-nginx

# Ver logs de un pod
kubectl logs -n ingress-nginx <nombre-del-pod>
```

---

**¡Eso es todo! Una vez completado, tendrás:**

✅ Cluster GKE configurado  
✅ NGINX Ingress Controller instalado  
✅ Namespace weather-tweets creado  
✅ IP externa para acceder a los servicios  

Luego solo ejecuta `bash scripts/quick-deploy.sh` y listo.
