package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int32  `json:"temperature"`
	Humidity     int32  `json:"humidity"`
	Weather      string `json:"weather"`
}

type ApiResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
	ID      string `json:"id"`
}

var (
	processed int64
	mu        sync.Mutex
	tweets    []WeatherTweet
)

// Handler para recibir tweets de la API Rust
func handleWeatherPost(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	var tweet WeatherTweet
	if err := json.NewDecoder(r.Body).Decode(&tweet); err != nil {
		http.Error(w, fmt.Sprintf("Error al decodificar JSON: %v", err), http.StatusBadRequest)
		return
	}

	// Incrementar contador
	count := atomic.AddInt64(&processed, 1)

	// Almacenar localmente
	mu.Lock()
	tweets = append(tweets, tweet)
	mu.Unlock()

	log.Printf("✓ Tweet #%d recibido: municipality=%s, temp=%d, humidity=%d, weather=%s",
		count, tweet.Municipality, tweet.Temperature, tweet.Humidity, tweet.Weather)

	// Simular envío a gRPC servers (Writers)
	go forwardToWriters(tweet)

	response := ApiResponse{
		Status:  "success",
		Message: "Tweet procesado por Go Client",
		ID:      fmt.Sprintf("go-tweet-%d", count),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// Simular envío a Writers (en fase 2 serán reales gRPC servers)
func forwardToWriters(tweet WeatherTweet) {
	// Aquí irían las llamadas a gRPC servers en fase 2
	// Por ahora solo logs
	log.Printf("📤 Reenviando tweet a Writers: %s", tweet.Municipality)
}

// Handler para obtener stats
func handleStats(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()

	response := map[string]interface{}{
		"total_processed":  atomic.LoadInt64(&processed),
		"tweets_in_memory": len(tweets),
		"service":          "Go Deployment 1 (gRPC Client)",
		"timestamp":        time.Now().Unix(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// Health check
func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

// Readiness check
func handleReady(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"ready":     true,
		"processed": atomic.LoadInt64(&processed),
	})
}

// Root endpoint
func handleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"service":      "Go Deployment 1 - gRPC Client",
		"version":      "1.0.0",
		"municipality": "chinautla",
		"endpoints": map[string]string{
			"POST /api/weather": "Recibir tweets de Rust API",
			"GET /stats":        "Obtener estadísticas",
			"GET /health":       "Health check",
			"GET /ready":        "Readiness check",
		},
	})
}

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("🚀 Go Deployment 1 (gRPC Client) iniciando en puerto %s", port)
	log.Printf("📍 Municipio: Chinautla")

	// Rutas
	http.HandleFunc("/", handleRoot)
	http.HandleFunc("/api/weather", handleWeatherPost)
	http.HandleFunc("/stats", handleStats)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/ready", handleReady)

	// Server HTTP
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", port),
		Handler:      http.DefaultServeMux,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		sigint := make(chan os.Signal, 1)
		signal.Notify(sigint, os.Interrupt, syscall.SIGTERM)
		<-sigint
		log.Println("⏹️  Deteniendo servidor...")
		srv.Close()
	}()

	// Iniciar servidor
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("❌ Error al iniciar servidor: %v", err)
	}

	log.Println("✓ Servidor detenido")
}
