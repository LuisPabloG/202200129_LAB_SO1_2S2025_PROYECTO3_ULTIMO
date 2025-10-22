# 📊 Importar Dashboard en Grafana

## Instrucciones para Importar el Dashboard

### Paso 1: Acceder a Grafana
1. Abre tu navegador y ve a: **http://136.112.59.160**
2. Inicia sesión con:
   - **Usuario:** admin
   - **Contraseña:** admin

### Paso 2: Importar el Dashboard
1. En el menú izquierdo, haz click en **"Dashboards"**
2. Haz click en **"+ New"** o en **"Import"**
3. Selecciona **"Import"**

### Paso 3: Subir el archivo JSON
1. Descarga el archivo `grafana-dashboard.json` de tu repositorio
2. En Grafana, en la sección "Import", copia y pega el contenido del JSON
3. O directamente arrastra el archivo JSON

### Paso 4: Configurar el Dashboard
1. Dale un nombre al dashboard (ej: "Weather Tweets")
2. Selecciona **"Valkey"** como Data Source
3. Haz click en **"Import"**

---

## 📌 Paneles incluidos en el Dashboard

### Visualización General
- **Distribución de Tweets por Municipio** (Pie Chart)
  - Muestra qué porcentaje de tweets vino de cada municipio

### Totales por Municipio (Stats)
- **Total Tweets Chinautla** (Verde)
- **Total Tweets Mixco** (Azul)
- **Total Tweets Guatemala** (Púrpura)
- **Total Tweets Amatitlán** (Naranja)

### Últimos Tweets (Tables)
- **Últimos 10 Tweets - Chinautla**
- **Últimos 10 Tweets - Mixco**
- **Últimos 10 Tweets - Guatemala**
- **Últimos 10 Tweets - Amatitlán**

### Contadores de Lista (Stats)
- **Total en Lista Chinautla**
- **Total en Lista Mixco**
- **Total en Lista Guatemala**
- **Total en Lista Amatitlán**

### Distribución de Climas por Municipio (Stats)
- **Tweets Sunny - Chinautla**
- **Tweets Cloudy - Chinautla**
- **Tweets Rainy - Chinautla**
- **Tweets Foggy - Chinautla**

---

## 🔄 Refresco Automático
El dashboard se refresca cada **5 segundos** automáticamente.

---

## ⚠️ Requisitos Previos
✅ Data Source "Valkey" configurado en Grafana  
✅ Go Deployment 1 recibiendo tweets  
✅ Locust ejecutándose y generando carga  
✅ Tweets almacenados en Valkey

---

## 📝 Queries Usadas

| Panel | Query |
|-------|-------|
| Total Chinautla | `GET count:chinautla` |
| Total Mixco | `GET count:mixco` |
| Total Guatemala | `GET count:guatemala` |
| Total Amatitlán | `GET count:amatitlan` |
| Últimos Tweets Chin | `LRANGE tweets:chinautla 0 9` |
| Últimos Tweets Mixco | `LRANGE tweets:mixco 0 9` |
| Últimos Tweets Guat | `LRANGE tweets:guatemala 0 9` |
| Últimos Tweets Amat | `LRANGE tweets:amatitlan 0 9` |
| Total Lista Chin | `LLEN tweets:chinautla` |
| Sunny Chinautla | `GET weather:chinautla:sunny` |
| Cloudy Chinautla | `GET weather:chinautla:cloudy` |
| Rainy Chinautla | `GET weather:chinautla:rainy` |
| Foggy Chinautla | `GET weather:chinautla:foggy` |

---

¡Listo para usar! 🚀
