# 📁 Estructura del Proyecto - SOPES1 Proyecto 3

## Vista General

```
proyecto3/
├── README.md (inicio)
├── ESTRUCTURA_PROYECTO.md (este archivo)
│
├── kubernetes/                    # Configuración Kubernetes (YAML)
│   ├── 00-namespaces.yaml
│   ├── 01-rust-api-deployment.yaml
│   ├── 02-go-deployment-1.yaml
│   ├── 03-ingress.yaml
│   ├── 04-go-deployment-1-loadbalancer.yaml
│   ├── 05-grafana-loadbalancer.yaml
│   ├── 06-zot-registry.yaml
│   ├── 07-grafana-redis-deployment.yaml
│   └── 08-locust-deployment.yaml
│
├── go-deployment-1/               # API Go (Valkey Writer)
│   ├── main.go
│   ├── go.mod
│   ├── go.sum
│   └── Dockerfile
│
├── locust/                        # Load Testing (Locust)
│   ├── locustfile.py
│   └── requirements.txt
│
├── scripts/                       # Scripts de Utilidad
│   ├── deployment/               # Scripts de despliegue
│   │   ├── build-images.sh       # Construir imágenes Docker
│   │   ├── deploy-phase1.sh      # Despliegue Fase 1
│   │   ├── deploy-quick.sh       # Despliegue rápido
│   │   └── push-to-zot.sh        # Push a registro Zot
│   │
│   ├── testing/                  # Scripts de testing
│   │   ├── run_locust_with_valkey.sh
│   │   └── test_load.py
│   │
│   └── utilities/                # Scripts utilitarios (agregar aquí otros)
│
├── docs/                          # Documentación
│   ├── guides/                    # Guías y tutoriales
│   │   ├── ACCESO_EXTERNO.md
│   │   ├── CLOUDSHELL_COMMANDS.md
│   │   ├── ENLACES_ACCESO_LOCAL.md
│   │   ├── FASE1_QUICKSTART.md
│   │   ├── GRAFANA_SETUP_MANUAL.md
│   │   ├── GUIA_COMPLETA.md
│   │   ├── IMPORT_GRAFANA_DASHBOARD.md
│   │   └── COMANDOS_LOCUST_KUBERNETES.md
│   │
│   ├── dashboards/               # Dashboards Grafana
│   │   ├── grafana-dashboard-final.json
│   │   └── grafana-dashboard.json
│   │
│   ├── commands/                 # Comandos comunes (agregar aquí)
│   │
│   └── locust_results.log        # Resultados de pruebas
│
├── proto/                         # Protobuf definitions
├── rust-api/                      # API Rust (no usado)
├── go-consumers/                  # Consumers Go (no usado)
├── go-writers/                    # Writers Go (no usado)
└── config/                        # Configuración global (para agregar)

```

---

## 🚀 Cómo Usar Esta Estructura

### 1️⃣ Despliegue Inicial
```bash
# Ver qué hacer
cat docs/guides/FASE1_QUICKSTART.md

# Ejecutar deployment
bash scripts/deployment/deploy-phase1.sh
```

### 2️⃣ Construir Imágenes
```bash
bash scripts/deployment/build-images.sh
```

### 3️⃣ Pruebas de Carga
```bash
bash scripts/testing/run_locust_with_valkey.sh
```

### 4️⃣ Ver Documentación
```bash
cd docs/guides
ls -la

# Leer guía específica
cat GUIA_COMPLETA.md
```

### 5️⃣ Acceder a Grafana
```bash
# Ver URLs de acceso
cat docs/guides/ACCESO_EXTERNO.md
```

---

## 📋 Resumen de Carpetas

| Carpeta | Contenido | Uso |
|---------|-----------|-----|
| `kubernetes/` | Archivos YAML de K8s | Despliegue en cluster |
| `go-deployment-1/` | Código fuente Go | API principal |
| `locust/` | Código Locust | Load testing |
| `scripts/deployment/` | Scripts de deploy | Automatizar despliegue |
| `scripts/testing/` | Scripts de testing | Pruebas |
| `docs/guides/` | Documentación | Leer instrucciones |
| `docs/dashboards/` | Dashboards Grafana | Configuración Grafana |

---

## 🔧 Agregar Nuevos Archivos

### Scripts de Deployment
```bash
# Agregar nuevo script
cp nuevo-script.sh scripts/deployment/
```

### Scripts de Testing
```bash
cp nuevo-test.sh scripts/testing/
```

### Documentación
```bash
cp nueva-guia.md docs/guides/
```

### Configuración
```bash
cp config.yaml config/
```

---

## 📌 Archivos Clave

- **README.md** - Inicio rápido
- **ESTRUCTURA_PROYECTO.md** - Este archivo
- **docs/guides/GUIA_COMPLETA.md** - Documentación completa
- **scripts/deployment/deploy-quick.sh** - Despliegue rápido
- **kubernetes/03-ingress.yaml** - Configuración Ingress

---

## 🎯 Siguiente Paso

1. Revisa `docs/guides/FASE1_QUICKSTART.md`
2. Ejecuta `scripts/deployment/deploy-quick.sh`
3. Accede a Grafana según `docs/guides/ACCESO_EXTERNO.md`
4. Lee las guías en `docs/guides/` para entender cada componente
