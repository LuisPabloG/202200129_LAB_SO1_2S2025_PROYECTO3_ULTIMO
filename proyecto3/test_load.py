#!/usr/bin/env python3
import requests
import json
import random
import time
import threading
from datetime import datetime

# Configuración
BASE_URL = "http://127.0.0.1:8081"
MUNICIPALITY = "chinautla"
WEATHERS = ["sunny", "cloudy", "rainy", "foggy"]
NUM_USERS = 10
DURATION_SECONDS = 120
REQUEST_PER_SECOND = 100  # Total requests per second

# Counters
total_requests = 0
successful_requests = 0
failed_requests = 0
start_time = None

def send_tweet():
    """Envía un tweet individual"""
    global total_requests, successful_requests, failed_requests
    
    tweet_data = {
        "municipality": MUNICIPALITY,
        "temperature": random.randint(15, 35),
        "humidity": random.randint(30, 90),
        "weather": random.choice(WEATHERS)
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/api/weather",
            json=tweet_data,
            timeout=10
        )
        
        total_requests += 1
        if response.status_code == 200:
            successful_requests += 1
        else:
            failed_requests += 1
            print(f"❌ Response {response.status_code}: {response.text[:100]}")
            
    except Exception as e:
        total_requests += 1
        failed_requests += 1
        print(f"❌ Error: {e}")

def user_worker(user_id, duration):
    """Worker que simula un usuario enviando requests"""
    user_start = time.time()
    request_count = 0
    
    while time.time() - user_start < duration:
        send_tweet()
        request_count += 1
        time.sleep(0.1)  # Pequeño delay entre requests
    
    print(f"👤 Usuario {user_id}: {request_count} requests completados")

def print_stats():
    """Imprime estadísticas cada 10 segundos"""
    global start_time, total_requests, successful_requests, failed_requests
    
    while time.time() - start_time < DURATION_SECONDS:
        time.sleep(10)
        elapsed = time.time() - start_time
        rate = total_requests / elapsed if elapsed > 0 else 0
        print(f"[{elapsed:5.1f}s] Total: {total_requests} | Success: {successful_requests} | Failed: {failed_requests} | Rate: {rate:.1f} req/s")

def check_stats_endpoint():
    """Verifica estadísticas del servidor periodicamente"""
    while time.time() - start_time < DURATION_SECONDS:
        try:
            response = requests.get(f"{BASE_URL}/stats", timeout=5)
            if response.status_code == 200:
                data = response.json()
                print(f"📊 Server Stats: {data}")
        except Exception as e:
            print(f"⚠️  Error getting stats: {e}")
        time.sleep(15)

def main():
    global start_time, total_requests, successful_requests, failed_requests
    
    print("=" * 70)
    print("🚀 LOCUST SIMULATION - Proyecto 3 SOPES1")
    print(f"📍 Municipio: {MUNICIPALITY}")
    print(f"👥 Usuarios: {NUM_USERS}")
    print(f"⏱️  Duración: {DURATION_SECONDS} segundos")
    print(f"🎯 Base URL: {BASE_URL}")
    print("=" * 70)
    
    start_time = time.time()
    
    # Crear threads para usuarios
    threads = []
    for i in range(NUM_USERS):
        t = threading.Thread(target=user_worker, args=(i+1, DURATION_SECONDS))
        t.daemon = True
        t.start()
        threads.append(t)
        time.sleep(0.5)  # Spawn rate: 2 usuarios por segundo
    
    # Thread para imprimir estadísticas
    stats_thread = threading.Thread(target=print_stats)
    stats_thread.daemon = True
    stats_thread.start()
    
    # Thread para revisar stats del endpoint
    check_stats_thread = threading.Thread(target=check_stats_endpoint)
    check_stats_thread.daemon = True
    check_stats_thread.start()
    
    # Esperar a que terminen todos los usuarios
    for t in threads:
        t.join()
    
    time.sleep(2)  # Extra time para finalizar
    
    elapsed = time.time() - start_time
    
    print("\n" + "=" * 70)
    print("✓ PRUEBA DE CARGA COMPLETADA")
    print("=" * 70)
    print(f"⏱️  Tiempo total: {elapsed:.2f} segundos")
    print(f"📊 Total de requests: {total_requests}")
    print(f"✅ Exitosos: {successful_requests}")
    print(f"❌ Fallos: {failed_requests}")
    print(f"📈 Tasa promedio: {total_requests/elapsed:.2f} req/s")
    
    if total_requests > 0:
        success_rate = (successful_requests / total_requests) * 100
        print(f"✨ Tasa de éxito: {success_rate:.1f}%")
    
    print("=" * 70)

if __name__ == "__main__":
    main()
