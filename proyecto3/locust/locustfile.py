import random
from locust import HttpUser, task, between, events
import json
import logging
import redis

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Conectar a Valkey - Usar IP del LoadBalancer
# Si tienes LoadBalancer, usa: redis.Redis(host='EXTERNAL_IP', port=6379)
# Si no, usa: redis.Redis(host='localhost', port=6379) y haz port-forward

# Opciones de conexión (descomentar la que funcione):
redis_client = None

# Opción 1: Conectar via puerto local (si haces port-forward)
try:
    redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True, socket_connect_timeout=5)
    redis_client.ping()
    logger.info("✓ Conectado a Valkey (localhost:6379)")
except Exception as e:
    logger.debug(f"⚠ No se pudo conectar a localhost:6379 - {e}")
    
# Opción 2: Si tienes IP externa de LoadBalancer, reemplaza aquí
# Descomentar y usar IP real de LoadBalancer:
# redis_client = redis.Redis(host='EXTERNAL_IP_AQUI', port=6379, decode_responses=True, socket_connect_timeout=5)

if redis_client is None:
    logger.warning("⚠ Valkey no disponible - solo funcionarán queries de Go API")

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
        logger.info(f"👤 Usuario iniciado - Municipio asignado: {ASSIGNED_MUNICIPALITY}")
    
    def get_municipality(self):
        """
        Retorna un municipio respetando tu carnet pero generando para todos
        70% de probabilidad para Chinautla (municipio asignado)
        10% cada uno para los otros municipios
        """
        if random.random() < 0.7:
            return "chinautla"
        return random.choice(["mixco", "guatemala", "amatitlan"])
    
    @task(1)
    def send_weather_tweet(self):
        """
        Envía un tweet del clima con estructura JSON
        Estructura según el proyecto: municipality, temperature, humidity, weather
        Prioriza Chinautla pero genera para TODOS los municipios
        También guarda datos en Valkey para Grafana
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
            # 1. Enviar al Go API
            response = self.client.post(
                "/api/weather",
                json=tweet_data,
                timeout=10
            )
            
            if response.status_code == 200:
                logger.debug(f"✓ Tweet enviado: {tweet_data}")
                
                # 2. Guardar datos adicionales en Valkey para Grafana
                if redis_client:
                    try:
                        # Guardar temperatura en lista
                        redis_client.lpush(f"temperatures:{municipality}", temperature)
                        
                        # Guardar humedad en lista
                        redis_client.lpush(f"humidity:{municipality}", humidity)
                        
                        # Contar por tipo de clima
                        redis_client.incr(f"weather:{municipality}:{weather}")
                        
                        # Guardar tweet ID en lista adicional
                        tweet_id = f"tweet-{random.randint(100000, 999999)}"
                        redis_client.lpush(f"tweets:{municipality}", tweet_id)
                        
                    except Exception as e:
                        logger.debug(f"Error guardando en Valkey: {e}")
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
