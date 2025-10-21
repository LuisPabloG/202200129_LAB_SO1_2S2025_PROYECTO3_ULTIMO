import random
from locust import HttpUser, task, between, events
import json
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Municipios y climas disponibles
MUNICIPALITIES = ["mixco", "guatemala", "amatitlan", "chinautla"]
WEATHERS = ["sunny", "cloudy", "rainy", "foggy"]

# Para este proyecto, enfocarse en chinautla (carnet 202200129)
ASSIGNED_MUNICIPALITY = "chinautla"

class WeatherLoadTest(HttpUser):
    """
    Simulador de carga para generar tweets del clima
    Carnet: 202200129 -> Municipio: Chinautla
    """
    
    wait_time = between(0.1, 0.5)  # Esperar entre 100ms a 500ms entre requests
    
    def on_start(self):
        """Ejecutado al iniciar cada usuario simulado"""
        logger.info(f"👤 Usuario {self.client_id} iniciado - Municipio asignado: {ASSIGNED_MUNICIPALITY}")
    
    @task(1)
    def send_weather_tweet(self):
        """
        Envía un tweet del clima con estructura JSON
        Estructura según el proyecto: municipality, temperature, humidity, weather
        """
        tweet_data = {
            "municipality": ASSIGNED_MUNICIPALITY,
            "temperature": random.randint(15, 35),  # 15°C a 35°C
            "humidity": random.randint(30, 90),      # 30% a 90%
            "weather": random.choice(WEATHERS)
        }
        
        try:
            response = self.client.post(
                "/api/weather",
                json=tweet_data,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.debug(f"✓ Tweet enviado: {tweet_data}")
            else:
                logger.warning(f"⚠ Respuesta no esperada: {response.status_code}")
                
        except Exception as e:
            logger.error(f"❌ Error al enviar tweet: {e}")
    
    @task(1)
    def check_stats(self):
        """
        Obtiene estadísticas del servidor cada cierto tiempo
        """
        try:
            response = self.client.get("/stats", timeout=5)
            if response.status_code == 200:
                data = response.json()
                logger.info(f"📊 Stats: {data.get('total_processed', 0)} tweets procesados")
        except Exception as e:
            logger.debug(f"Error obteniendo stats: {e}")
    
    @task(1)
    def health_check(self):
        """
        Verifica la salud del servicio
        """
        try:
            response = self.client.get("/health", timeout=5)
            if response.status_code == 200:
                logger.debug("✓ Health check OK")
        except Exception as e:
            logger.warning(f"⚠ Health check falló: {e}")


@events.test_start.add_listener
def on_test_start(environment, **kwargs):
    """Se ejecuta cuando inicia la prueba de carga"""
    logger.info("=" * 60)
    logger.info("🚀 Iniciando prueba de carga - Proyecto 3 SOPES1")
    logger.info("📍 Municipio asignado: CHINAUTLA")
    logger.info("🎯 Objetivo: 10,000 peticiones con 10 usuarios concurrentes")
    logger.info("=" * 60)


@events.test_stop.add_listener
def on_test_stop(environment, **kwargs):
    """Se ejecuta cuando termina la prueba de carga"""
    logger.info("=" * 60)
    logger.info("✓ Prueba de carga finalizada")
    logger.info(f"📊 Total de requests: {environment.stats.total.num_requests}")
    logger.info(f"❌ Total de fallos: {environment.stats.total.num_failures}")
    logger.info("=" * 60)
