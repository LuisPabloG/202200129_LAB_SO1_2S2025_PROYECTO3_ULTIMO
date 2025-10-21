import random
from locust import HttpUser, task, between
from datetime import datetime

MUNICIPALITIES = ["mixco", "guatemala", "amatitlan", "chinautla"]
WEATHERS = ["sunny", "cloudy", "rainy", "foggy"]


class WeatherTweetUser(HttpUser):
    wait_time = between(0.5, 2)

    @task
    def send_tweet(self):
        """Envía un tweet de clima al API"""
        tweet = {
            "municipality": random.choice(MUNICIPALITIES),
            "temperature": random.randint(15, 35),
            "humidity": random.randint(30, 95),
            "weather": random.choice(WEATHERS),
        }
        
        # Enviamos al Ingress
        self.client.post(
            "/api/tweet",
            json=tweet,
            headers={"Content-Type": "application/json"}
        )

    @task
    def check_stats(self):
        """Verifica estadísticas del API"""
        self.client.get("/api/stats")

    def on_start(self):
        """Se ejecuta cuando comienza el test"""
        print(f"[{datetime.now()}] Usuario iniciado")

    def on_stop(self):
        """Se ejecuta cuando termina el test"""
        print(f"[{datetime.now()}] Usuario detenido")
