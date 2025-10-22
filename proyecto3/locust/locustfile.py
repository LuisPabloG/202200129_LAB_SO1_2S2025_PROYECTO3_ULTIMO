import random
from locust import HttpUser, task, between, events
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Municipios y climas disponibles
MUNICIPALITIES = ["mixco", "guatemala", "amatitlan", "chinautla"]
WEATHERS = ["sunny", "cloudy", "rainy", "foggy"]

# Carnet: 202200129 → Municipio asignado: Chinautla
ASSIGNED_MUNICIPALITY = "chinautla"

class WeatherLoadTest(HttpUser):
    """
    Generador de tráfico para prueba de carga
    Requisito: Generar JSON con {municipality, temperature, humidity, weather}
    hacia el Ingress Controller (http://34.121.14.130/api/weather)
    """
    
    wait_time = between(0.1, 0.5)
    
    def get_municipality(self):
        """
        Distribución de municipios:
        - 70% Chinautla (carnet 202200129 → municipio asignado)
        - 30% otros (10% Mixco, 10% Guatemala, 10% Amatitlán)
        """
        if random.random() < 0.7:
            return "chinautla"
        return random.choice(["mixco", "guatemala", "amatitlan"])
    
    @task
    def send_weather_tweet(self):
        """
        Envía tweet del clima con estructura JSON especificada
        POST /api/weather {municipality, temperature, humidity, weather}
        """
        municipality = self.get_municipality()
        temperature = random.randint(15, 35)
        humidity = random.randint(30, 90)
        weather = random.choice(WEATHERS)
        
        tweet_data = {
            "municipality": municipality,
            "temperature": temperature,
            "humidity": humidity,
            "weather": weather
        }
        
        try:
            response = self.client.post(
                "/api/weather",
                json=tweet_data,
                timeout=10,
                name="/api/weather"
            )
            
            if response.status_code == 200:
                logger.debug(f"✓ {municipality} - {temperature}°C, {humidity}%, {weather}")
            else:
                logger.warning(f"⚠ Error {response.status_code}")
                
        except Exception as e:
            logger.error(f"❌ Error: {e}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    logger.info("=" * 70)
    logger.info("🚀 PRUEBA DE CARGA - PROYECTO 3 SOPES1")
    logger.info("📍 Carnet: 202200129 → Municipio: CHINAUTLA")
    logger.info("🎯 Objetivo: 10,000 peticiones con 10 usuarios concurrentes")
    logger.info("📡 Destino: Ingress Controller (34.121.14.130/api/weather)")
    logger.info("=" * 70)


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    logger.info("=" * 70)
    logger.info("✓ PRUEBA DE CARGA FINALIZADA")
    logger.info(f"📊 Total requests: {environment.stats.total.num_requests}")
    logger.info(f"❌ Total fallos: {environment.stats.total.num_failures}")
    logger.info(f"⏱️ Tiempo promedio: {environment.stats.total.avg_response_time:.2f}ms")
    logger.info("=" * 70)
