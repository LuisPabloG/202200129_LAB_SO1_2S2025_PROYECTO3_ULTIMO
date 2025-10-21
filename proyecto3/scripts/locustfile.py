from locust import HttpUser, task, between
import random
import json

# Municipios según carnet 202200129 (último dígito 9 = chinautla)
MUNICIPALITIES = {
    "mixco": 1,
    "guatemala": 2,
    "amatitlan": 3,
    "chinautla": 4,
}

WEATHERS = {
    "sunny": 1,
    "cloudy": 2,
    "rainy": 3,
    "foggy": 4,
}

class WeatherUser(HttpUser):
    wait_time = between(0.1, 0.5)  # Espera aleatoria entre 100ms y 500ms

    @task(1)
    def send_weather_tweet(self):
        """Envía un tweet meteorológico"""
        payload = {
            "municipality": MUNICIPALITIES["chinautla"],
            "temperature": random.randint(15, 35),
            "humidity": random.randint(40, 90),
            "weather": random.randint(1, 4),
        }

        self.client.post(
            "/weather",
            json=payload,
            headers={"Content-Type": "application/json"},
        )

    @task(1)
    def health_check(self):
        """Verifica el estado de la API"""
        self.client.get("/health")
