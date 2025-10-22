# Comandos para Ejecutar Locust en Kubernetes

## 1. Navega a tu directorio del proyecto
```bash
cd ~/202200129_LAB_SO1_2S2025_PROYECTO3_ULTIMO/proyecto3
```

## 2. Despliega Locust en Kubernetes
```bash
kubectl apply -f kubernetes/08-locust-deployment.yaml
```

## 3. Verifica que los pods estén corriendo
```bash
kubectl get pods -n weather-system | grep locust
```

Deberías ver:
- `locust-master-xxxxx` (RUNNING)
- `locust-worker-xxxxx` (RUNNING)

## 4. Obtén la IP externa del LoadBalancer de Locust
```bash
kubectl get svc -n weather-system | grep locust-master
```

O espera a que asigne IP:
```bash
kubectl get svc -n weather-system locust-master -w
```

## 5. Accede a la interfaz web de Locust
Una vez que tengas la IP externa, accede a:
```
http://<EXTERNAL-IP>:8089
```

Por ejemplo: `http://34.121.14.131:8089`

## 6. Verifica los logs
```bash
kubectl logs -n weather-system -f deployment/locust-master
kubectl logs -n weather-system -f deployment/locust-worker
```

## 7. Para aumentar workers (más carga)
```bash
kubectl scale deployment locust-worker -n weather-system --replicas=3
```

## 8. Para detener la prueba
```bash
kubectl delete deployment locust-master locust-worker -n weather-system
kubectl delete svc locust-master -n weather-system
kubectl delete configmap locust-config -n weather-system
```

---

## Notas:
- **Master**: Orquesta la prueba (puerto 8089 = web, 5557 = comunicación con workers)
- **Worker**: Ejecuta las peticiones (se comunica con el master)
- **Duration**: 1 hora (puedes cambiar `-t 1h` a `-t 10h` en el YAML)
- **Users**: 10 usuarios concurrentes
- **Spawn rate**: 2 usuarios por segundo
- **Target**: Ingress Controller (weather-ingress)

## Para escalar horizontalmente:
1. Aumenta `replicas: 3` en la sección `locust-worker`
2. O usa: `kubectl scale deployment locust-worker -n weather-system --replicas=5`
