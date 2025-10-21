use actix_web::{web, App, HttpServer, HttpResponse, Responder};
use serde::{Deserialize, Serialize};
use std::sync::{Arc, Mutex};

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

pub struct AppState {
    pub counter: Arc<Mutex<u64>>,
}

async fn post_weather(
    state: web::Data<AppState>,
    tweet: web::Json<WeatherTweet>,
) -> impl Responder {
    let mut counter = state.counter.lock().unwrap();
    *counter += 1;
    let id = format!("tweet-{}", counter);
    
    println!("✓ Tweet #{}: municipality={}, temp={}, humidity={}, weather={}",
        counter, tweet.municipality, tweet.temperature, tweet.humidity, tweet.weather);
    
    HttpResponse::Ok().json(ApiResponse {
        status: "success".to_string(),
        message: "Tweet recibido".to_string(),
        id,
    })
}

async fn get_weather(state: web::Data<AppState>) -> impl Responder {
    let counter = state.counter.lock().unwrap();
    HttpResponse::Ok().json(serde_json::json!({
        "total_tweets": *counter,
        "status": "ok"
    }))
}

async fn health() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({"status": "healthy"}))
}

async fn index() -> impl Responder {
    HttpResponse::Ok().json(serde_json::json!({
        "service": "Weather API",
        "version": "1.0.0",
        "municipality": "chinautla"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    let bind_address = format!("0.0.0.0:{}", port);
    
    println!("🚀 Iniciando Weather API en {}", bind_address);
    
    let state = web::Data::new(AppState {
        counter: Arc::new(Mutex::new(0)),
    });
    
    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            .route("/", web::get().to(index))
            .route("/health", web::get().to(health))
            .route("/api/weather", web::post().to(post_weather))
            .route("/api/weather", web::get().to(get_weather))
    })
    .bind(&bind_address)?
    .run()
    .await
}
