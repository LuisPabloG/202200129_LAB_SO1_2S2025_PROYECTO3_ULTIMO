# 🎯 GUÍA COMPLETA - Proyecto 3 Weather Tweets

## 📋 Resumen de tu Sistema

Tu proyecto cuenta con:
- **Go Deployment 1** (Valkey Writer) en puerto 8081
- **Grafana** (Visualización) en puerto 3000 (internal), LoadBalancer: 136.112.59.160
- **Valkey** (Base de datos en memoria) en puerto 6379
- **Locust** (Generador de carga) en puerto 8093
- **Municipio asignado:** CHINAUTLA (Carnet 202200129 → último dígito 9)

---

## 🚀 PASOS PARA EJECUTAR TODO

### PASO 1: Iniciar Locust con la nueva configuración
```bash
cd /home/luis-pablo-garcia/Escritorio/PROYECTO-SISTEMAS-OPERATIVOS/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3

docker run --rm -p 8093:8089 \
  -v $(pwd):/app \
  python:3.11-slim bash -c "cd /app && pip install -q -r locust/requirements.txt && locust -f locust/locustfile.py -H http://34.70.218.90 --web-host=0.0.0.0"
```

**Espera a que inicie (unos 10-15 segundos)**

### PASO 2: Acceder a Locust
1. Abre tu navegador: **http://localhost:8093**
2. Configura:
   - **Host:** http://34.70.218.90
   - **Number of users:** 10
   - **Spawn rate:** 2
3. Click en **"Start swarming"**

**Dejar que genere tweets por 2-3 minutos**

### PASO 3: Verificar que hay datos en Valkey
1. Abre Grafana: **http://136.112.59.160**
2. Inicia sesión: admin/admin
3. Ve a: **Dashboards → Browse**
4. Busca tu dashboard importado

### PASO 4: Importar el Dashboard
1. En Grafana, ve a: **Dashboards → Import**
2. Copia y pega el contenido de: `grafana-dashboard.json`
3. O sube el archivo directamente
4. Selecciona **"Valkey"** como Data Source
5. Click **"Import"**

### PASO 5: Ver el Dashboard en acción
1. Una vez importado, verás todos los paneles
2. El dashboard se actualiza cada 5 segundos automáticamente
3. Verás:
   - Gráfico de distribución de tweets por municipio
   - Totales por cada municipio
   - Últimos 10 tweets de cada municipio
   - Distribución de climas (sunny, cloudy, rainy, foggy)

---

## 📊 Qué esperar en Grafana

### Valores que crecerán mientras Locust está corriendo:
```
✅ count:chinautla    → ~7 de cada 10 tweets (70%)
✅ count:mixco        → ~1-2 de cada 10 tweets (10-20%)
✅ count:guatemala    → ~1-2 de cada 10 tweets (10-20%)
✅ count:amatitlan    → ~0-1 de cada 10 tweets (5-10%)

✅ weather:chinautla:sunny   → Contador de sunny en Chinautla
✅ weather:chinautla:cloudy  → Contador de cloudy en Chinautla
✅ weather:chinautla:rainy   → Contador de rainy en Chinautla
✅ weather:chinautla:foggy   → Contador de foggy en Chinautla

✅ tweets:chinautla   → Lista de últimos tweet IDs
✅ temperatures:chinautla → Lista de temperaturas
✅ humidity:chinautla → Lista de humedad
```

---

## 🔗 URLs Principales

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| Locust | http://localhost:8093 | Sin autenticación |
| Grafana | http://136.112.59.160 | admin / admin |
| Go API | http://34.70.218.90 | Sin autenticación |
| Zot Registry | http://34.122.188.200:5000 | (Solo consulta) |

---

## 📈 Monitorear en tiempo real

1. **Grafana:**
   - El dashboard se actualiza cada 5 segundos
   - Verás cómo crecen los contadores

2. **Locust:**
   - Muestra RPS (requests por segundo)
   - Total de peticiones exitosas/fallidas
   - Latencia promedio

3. **Valkey (desde Cloud Shell):**
   ```bash
   kubectl exec -n weather-system -it <valkey-pod-name> -- redis-cli
   > GET count:chinautla
   > LLEN tweets:chinautla
   > KEYS weather:chinautla:*
   ```

---

## 🧹 Limpiar cuando termines

```bash
# Detener Locust
docker stop $(docker ps -q)

# Limpiar contenedores
docker rm $(docker ps -aq)
```

---

## ✅ Checklist Final

- [ ] Locust corriendo en http://localhost:8093
- [ ] 10 usuarios, 2 spawn rate, iniciado el swarming
- [ ] Dashboard importado en Grafana
- [ ] Todos los paneles mostrando datos
- [ ] Datos se actualizan cada 5 segundos
- [ ] Contadores incrementando mientras Locust corre
- [ ] Últimos tweets apareciendo en tablas

---

## 🎯 Meta

Generar **10,000 peticiones** con 10 usuarios concurrentes y visualizar todos los datos en Grafana en tiempo real. 🚀

