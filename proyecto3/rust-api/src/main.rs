use actix_web::{web, App, HttpServer, HttpResponse, middleware, Responder};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};
use std::collections::HashMap;
use tokio::time::{self, Duration};
use log::info;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct WeatherTweet {
    pub municipality: String,
    pub temperature: i32,
    pub humidity: i32,
    pub weather: String,
}

#[derive(Debug, Serialize)]
pub struct ApiResponse {
    pub status: String,
    pub message: String,
    pub id: String,
}

// Estado compartido para almacenar tweets
pub struct AppState {
    pub tweets: Arc<Mutex<Vec<WeatherTweet>>>,
    pub counter: Arc<Mutex<u64>>,
}

// Handler para POST /api/weather
async fn post_weather(
    state: web::Data<AppState>,
    tweet: web::Json<WeatherTweet>,
) -> impl Responder {
    let mut tweets = state.tweets.lock().unwrap();
    let mut counter = state.counter.lock().unwrap();
    
    *counter += 1;
    let tweet_id = format!("tweet-{}", counter);
    
    tweets.push(tweet.into_inner());
    
    info!(
        "✓ Tweet recibido #{}: municipality={}, temp={}, humidity={}, weather={}",
        counter,
        tweets.last().unwrap().municipality,
        tweets.last().unwrap().temperature,
        tweets.last().unwrap().humidity,
        tweets.last().unwrap().weather
    );
    
    HttpResponse::Ok().json(ApiResponse {
        status: "success".to_string(),
        message: "Tweet procesado correctamente".to_string(),
        id: tweet_id,
    })
}

// Handler para GET /api/weather (obtener todos los tweets)
async fn get_weather(
    state: web::Data<AppState>,
) -> impl Responder {
    let tweets = state.tweets.lock().unwrap();
    let counter = state.counter.lock().unwrap();
    
    HttpResponse::Ok().json(serde_json::json!({
        "total_tweets": *counter,
        "tweets_in_memory": tweets.len(),
        "tweets": tweets.clone()
    }))
}

// Handler para GET /health (liveness probe)
async fn health() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "weather-api"
    }))
}

// Handler para GET /ready (readiness probe)
async fn ready(
    state: web::Data<AppState>,
) -> impl Responder {
    let counter = state.counter.lock().unwrap();
    
    HttpResponse::Ok().json(serde_json::json!({
        "ready": true,
        "tweets_processed": *counter
    }))
}

// Handler raíz
async fn index() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "service": "Weather API",
        "version": "1.0.0",
        "municipality": "chinautla",
        "endpoints": {
            "POST /api/weather": "Enviar un nuevo tweet del clima",
            "GET /api/weather": "Obtener todos los tweets",
            "GET /health": "Health check",
            "GET /ready": "Readiness check"
        }
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));
    
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let bind_address = format!("0.0.0.0:{}", port);
    
    info!("🚀 Iniciando Weather API en {}", bind_address);
    info!("📍 Municipio: Chinautla");
    
    let state = web::Data::new(AppState {
        tweets: Arc::new(Mutex::new(Vec::new())),
        counter: Arc::new(Mutex::new(0)),
    });
    
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .wrap(middleware::Logger::default())
            .route("/", web::get().to(index))
            .route("/health", web::get().to(health))
            .route("/ready", web::get().to(ready))
            .route("/api/weather", web::post().to(post_weather))
            .route("/api/weather", web::get().to(get_weather))
    })
    .bind(&bind_address)?
    .run()
    .await
}
