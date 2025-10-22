# 🔧 COMANDOS PARA EJECUTAR EN CLOUD SHELL

## 1. Verificar estado de Grafana
```bash
kubectl get pods -n weather-system | grep grafana
kubectl describe pod -n weather-system -l app=grafana-redis
```

## 2. Ver logs de Grafana
```bash
kubectl logs -n weather-system -l app=grafana-redis --tail=50
```

## 3. Esperar a que esté listo
```bash
kubectl wait --for=condition=ready pod -n weather-system -l app=grafana-redis --timeout=300s
```

## 4. Verificar que el puerto esté abierto
```bash
kubectl get svc grafana-lb -n weather-system -o wide
```

## 5. Probar conectividad
```bash
kubectl exec -n weather-system -it $(kubectl get pod -n weather-system -l app=grafana-redis -o jsonpath='{.items[0].metadata.name}') -- curl -s http://localhost:3000/api/health
```

## 6. Verificar logs de inicio de Grafana
```bash
kubectl logs -n weather-system $(kubectl get pod -n weather-system -l app=grafana-redis -o jsonpath='{.items[0].metadata.name}') | head -50
```

---

Si Grafana sigue sin responder, ejecuta esto para reiniciarlo:

```bash
kubectl delete pod -n weather-system -l app=grafana-redis
sleep 5
kubectl get pods -n weather-system | grep grafana
```

Luego espera 30-40 segundos y prueba nuevamente el navegador.
