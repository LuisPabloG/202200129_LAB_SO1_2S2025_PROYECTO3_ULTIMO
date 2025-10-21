# 🌐 ENLACES PARA ACCESO LOCAL - Proyecto 3 SOPES1

## Información General
- **Fecha**: 21 de octubre de 2025
- **Carnet**: 202200129
- **Municipio asignado**: Chinautla
- **Estado**: ✅ Go Deployment 1 corriendo con Valkey
- **Status**: Listos para carga de prueba

---

## 🎯 ACCESOS PRINCIPALES

### 1. **Go Deployment 1 API** (Receptor de tweets)
- **URL**: http://localhost:8081
- **Puerto**: 8081
- **Descripción**: Servicio que recibe tweets del clima y los almacena en Valkey

#### Endpoints disponibles:
```
POST   http://localhost:8081/api/weather    → Enviar tweet
GET    http://localhost:8081/stats          → Ver estadísticas
GET    http://localhost:8081/health         → Health check
GET    http://localhost:8081/ready          → Readiness check
GET    http://localhost:8081/               → Info del servicio
```

#### Ejemplo de request POST:
```bash
curl -X POST http://localhost:8081/api/weather \
  -H "Content-Type: application/json" \
  -d '{
    "municipality": "chinautla",
    "temperature": 28,
    "humidity": 65,
    "weather": "sunny"
  }'
```

#### Ejemplo de request GET stats:
```bash
curl http://localhost:8081/stats | jq .
```

---

### 2. **Grafana Dashboard** (Visualización de datos)
- **URL**: http://localhost:3000
- **Puerto**: 3000
- **Usuario por defecto**: admin
- **Contraseña por defecto**: admin
- **Descripción**: Plataforma de visualización para monitorear tweets en Valkey

#### Tareas pendientes en Grafana:
1. Agregar Data Source de Redis/Valkey
   - Hostname: `valkey` (desde dentro del cluster)
   - Puerto: `6379`
2. Crear dashboard con panels para mostrar:
   - Contador de tweets por municipio
   - Últimos tweets almacenados
   - Gráficos de temperatura/humedad

---

### 3. **Valkey/Redis** (Base de datos)
- **Hostname en cluster**: valkey
- **Puerto**: 6379
- **IP interna del cluster**: 10.52.0.6:6379
- **Descripción**: Almacenamiento en memoria para tweets

#### Estructura de datos en Valkey:
```
weather:chinautla:1    → JSON del primer tweet
weather:chinautla:2    → JSON del segundo tweet
...
count:chinautla        → Contador total de tweets para Chinautla
tweets:chinautla       → Lista de IDs de tweets
```

---

## 📊 HERRAMIENTAS PARA TESTING

### 1. **Test con cURL** (Manual, request único)
```bash
# Enviar un tweet
curl -X POST http://localhost:8081/api/weather \
  -H "Content-Type: application/json" \
  -d '{
    "municipality": "chinautla",
    "temperature": '$(shuf -i 15-35 -n 1)',
    "humidity": '$(shuf -i 30-90 -n 1)',
    "weather": "'$(shuf -e sunny cloudy rainy foggy -n 1)'"
  }'

# Ver estadísticas
curl http://localhost:8081/stats | jq .

# Health check
curl http://localhost:8081/health | jq .
```

### 2. **Test con Python** (Carga automática)
Ubicación: `/home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3/test_load.py`

```bash
# Ejecutar via Docker
docker run --rm --network host \
  -v /home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3:/app \
  python:3.11-slim bash -c "cd /app && pip install requests -q && python3 test_load.py"
```

### 3. **Test con Locust** (Si tienes instalado)
```bash
locust -f /ruta/a/locustfile.py -H http://localhost:8081 \
  --users 10 --spawn-rate 2 --run-time 2m --headless
```

---

## 🔧 VERIFICACIÓN DE ESTADO

### Ver pods corriendo:
```bash
export KUBECONFIG=~/.kube/config-gke
kubectl get pods -n weather-system
```

### Ver logs del Go service:
```bash
export KUBECONFIG=~/.kube/config-gke
kubectl logs -f deployment/go-deployment-1 -n weather-system
```

### Ver logs de Grafana:
```bash
export KUBECONFIG=~/.kube/config-gke
kubectl logs -f deployment/grafana -n weather-system
```

### Ver datos en Valkey (desde dentro del cluster):
```bash
export KUBECONFIG=~/.kube/config-gke
kubectl exec -it $(kubectl get pod -n weather-system -l app=valkey -o jsonpath='{.items[0].metadata.name}') -- redis-cli
# Dentro de redis-cli:
KEYS weather:*
GET weather:chinautla:1
GET count:chinautla
```

---

## 📋 CHECKLIST DE ACCESO

- ✅ Go Deployment 1 running → **http://localhost:8081**
- ✅ Grafana running → **http://localhost:3000**
- ✅ Valkey running → **valkey:6379**
- ⏳ Port-forwards activos en terminal actual
- ⏳ Listos para ejecutar carga de prueba

---

## ⚡ PRÓXIMOS PASOS

1. **Acceder a Grafana** → http://localhost:3000
2. **Agregar Data Source** (Redis)
3. **Crear Dashboards** para visualizar datos
4. **Ejecutar carga de prueba** con test_load.py o Locust
5. **Monitorear en Grafana** en tiempo real

---

## 📝 NOTAS IMPORTANTES

- Los port-forwards deben mantenerse activos en una terminal
- Cada ejecución del script de carga reset el contador
- Los datos persisten en Valkey durante 24 horas
- El municipio asignado es **Chinautla** (carnet 202200129)

---

**Última actualización**: 21 de octubre de 2025, 16:53
