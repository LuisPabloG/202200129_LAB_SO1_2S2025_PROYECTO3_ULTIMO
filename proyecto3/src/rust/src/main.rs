use actix_web::{web, App, HttpServer, HttpResponse, middleware};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::RwLock;
use log::info;

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct WeatherTweet {
    municipality: i32,
    temperature: i32,
    humidity: i32,
    weather: i32,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    let counter = Arc::new(RwLock::new(0));

    info!("Starting Weather API on 0.0.0.0:8080");

    HttpServer::new(move || {
        let counter = Arc::clone(&counter);
        App::new()
            .app_data(web::Data::new(counter))
            .wrap(middleware::Logger::default())
            .route("/health", web::get().to(health_check))
            .route("/weather", web::post().to(receive_weather))
    })
    .bind("0.0.0.0:8080")?
    .workers(num_cpus::get())
    .run()
    .await
}

async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({"status": "ok"}))
}

async fn receive_weather(
    tweet: web::Json<WeatherTweet>,
    counter: web::Data<Arc<RwLock<i32>>>,
) -> HttpResponse {
    let mut count = counter.write().await;
    *count += 1;

    info!("Received weather tweet: {:?}, Total: {}", tweet, *count);

    // TODO: Send to Go gRPC service here

    HttpResponse::Ok().json(serde_json::json!({
        "status": "received",
        "total_processed": *count
    }))
}
