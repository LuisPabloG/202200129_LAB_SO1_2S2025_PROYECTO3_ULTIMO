use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::Arc;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct WeatherTweet {
    pub municipality: String,
    pub temperature: i32,
    pub humidity: i32,
    pub weather: String,
}

#[derive(Serialize)]
struct Response {
    status: String,
    message: String,
}

// Contador global de tweets recibidos
static TWEET_COUNTER: AtomicU64 = AtomicU64::new(0);

async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(Response {
        status: "ok".to_string(),
        message: "API Rust is running".to_string(),
    })
}

async fn receive_tweet(tweet: web::Json<WeatherTweet>) -> HttpResponse {
    let count = TWEET_COUNTER.fetch_add(1, Ordering::SeqCst);
    
    println!("Tweet recibido #{}: {:?}", count + 1, tweet);
    
    // Aquí después conectaremos con Go para enviar a Kafka/RabbitMQ
    
    HttpResponse::Ok().json(Response {
        status: "received".to_string(),
        message: format!("Tweet #{} procesado", count + 1),
    })
}

async fn stats() -> HttpResponse {
    let count = TWEET_COUNTER.load(Ordering::SeqCst);
    HttpResponse::Ok().json(serde_json::json!({
        "total_tweets": count,
        "status": "running"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::default().default_filter_or("info"));

    let host = std::env::var("HOST").unwrap_or_else(|_| "0.0.0.0".to_string());
    let port = std::env::var("PORT").unwrap_or_else(|_| "8080".to_string());
    
    let addr = format!("{}:{}", host, port);
    
    println!("🚀 API Rust iniciando en {}", addr);

    HttpServer::new(|| {
        App::new()
            .wrap(middleware::Logger::default())
            .route("/health", web::get().to(health_check))
            .route("/tweet", web::post().to(receive_tweet))
            .route("/stats", web::get().to(stats))
    })
    .bind(&addr)?
    .run()
    .await
}
