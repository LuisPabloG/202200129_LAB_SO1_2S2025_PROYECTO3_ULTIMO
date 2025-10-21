# 🚀 INSTRUCCIONES PARA CONFIGURAR GRAFANA CON REDIS

## OPCIÓN 1: Ejecutar desde Google Cloud Shell (RECOMENDADO)

1. **Abre Google Cloud Shell:**
   - Ve a https://console.cloud.google.com
   - Haz click en el ícono de terminal en la esquina superior derecha
   - O ve a: https://shell.cloud.google.com

2. **Clona tu repositorio:**
   ```bash
   git clone https://github.com/LuisPabloG/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO.git
   cd 202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3
   ```

3. **Dale permiso de ejecución al script:**
   ```bash
   chmod +x scripts/setup-grafana-redis.sh
   ```

4. **Ejecuta el script:**
   ```bash
   ./scripts/setup-grafana-redis.sh
   ```

   Verás algo como:
   ```
   🚀 Configurando Grafana con plugin de Redis en GKE...
   🗑️  Removiendo Grafana antiguo...
   📦 Desplegando Grafana con plugin de Redis...
   ⏳ Esperando a que Grafana inicie...
   ...
   ✅ GRAFANA CONFIGURADO
   
   NAME        TYPE         CLUSTER-IP   EXTERNAL-IP    PORT(S)   AGE
   grafana-lb  LoadBalancer 34.xxx.x.x   136.112.59.xxx 80:xxxx   ...
   ```

5. **Copia la IP EXTERNAL-IP de grafana-lb**

6. **Accede a Grafana en navegador:**
   ```
   http://<EXTERNAL-IP>
   ```
   
   Usuario: `admin`
   Contraseña: `admin`

---

## OPCIÓN 2: Ejecución Manual (Si prefieres control total)

1. **En Cloud Shell, ejecuta comando por comando:**

```bash
# 1. Eliminar Grafana viejo
kubectl delete deployment grafana -n weather-system

# 2. Desplegar Grafana con Redis
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: grafana-redis
  namespace: weather-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: grafana-redis
  template:
    metadata:
      labels:
        app: grafana-redis
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:latest
        env:
        - name: GF_SECURITY_ADMIN_USER
          value: admin
        - name: GF_SECURITY_ADMIN_PASSWORD
          value: admin
        - name: GF_INSTALL_PLUGINS
          value: redis-datasource
        ports:
        - containerPort: 3000
EOF

# 3. Esperar a que esté listo
kubectl wait --for=condition=available --timeout=300s deployment/grafana-redis -n weather-system

# 4. Crear LoadBalancer
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: grafana-lb
  namespace: weather-system
spec:
  type: LoadBalancer
  selector:
    app: grafana-redis
  ports:
  - port: 80
    targetPort: 3000
EOF

# 5. Ver IP externa
kubectl get svc grafana-lb -n weather-system -o wide
```

---

## ✅ Una vez en Grafana:

1. **Login:**
   - Usuario: `admin`
   - Contraseña: `admin`

2. **Agregar Data Source de Redis:**
   - Ve a: Configuration → Data Sources → Add data source
   - Selecciona: "Redis"
   - Nombre: "Valkey"
   - URL: `http://valkey.weather-system:6379`
   - Save & Test

3. **Crear Dashboard:**
   - Ve a: Dashboards → New Dashboard
   - Add Panel
   - Data Source: "Valkey"
   - Query:
     ```
     KEYS weather:chinautla:*
     ```
   - O para contar:
     ```
     GET count:chinautla
     ```

4. **Visualizar tweets en tiempo real:**
   - Ejecuta Locust
   - El dashboard mostrará los datos en vivo

---

## 🔗 URLS FINALES:

- **Go API:**      http://34.70.218.90
- **Grafana:**     http://<nueva-IP-grafana>
- **Zot Registry:** http://34.122.188.200:5000

---

## 📝 NOTAS:

- El script instala automáticamente el plugin de Redis
- Grafana se configure con admin/admin (cambia después en producción)
- El data source se crea automáticamente apuntando a Valkey
- Todos los datos persisten en el cluster
