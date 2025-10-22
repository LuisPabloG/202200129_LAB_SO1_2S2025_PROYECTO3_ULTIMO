package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
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
	rdb       *redis.Client
)

// Inicializar conexión a Valkey/Redis
func initRedis() error {
	redisHost := os.Getenv("REDIS_HOST")
	if redisHost == "" {
		redisHost = "valkey"
	}
	redisPort := os.Getenv("REDIS_PORT")
	if redisPort == "" {
		redisPort = "6379"
	}

	rdb = redis.NewClient(&redis.Options{
		Addr: fmt.Sprintf("%s:%s", redisHost, redisPort),
	})

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err := rdb.Ping(ctx).Err()
	if err != nil {
		return fmt.Errorf("no se puede conectar a Redis: %w", err)
	}

	log.Printf("✓ Conectado a Valkey en %s:%s", redisHost, redisPort)
	return nil
}

// Handler para recibir tweets
func handleWeatherPost(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "Método no permitido", http.StatusMethodNotAllowed)
		return
	}

	var tweet WeatherTweet
	if err := json.NewDecoder(r.Body).Decode(&tweet); err != nil {
		http.Error(w, fmt.Sprintf("Error al decodificar: %v", err), http.StatusBadRequest)
		return
	}

	count := atomic.AddInt64(&processed, 1)
	id := fmt.Sprintf("tweet-%d", count)

	// Guardar en Valkey con estructura weather:{municipality}:{id} = JSON
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	key := fmt.Sprintf("weather:%s:%d", tweet.Municipality, count)
	tweetJSON, _ := json.Marshal(tweet)

	// 1. Guardar tweet JSON completo
	err := rdb.Set(ctx, key, string(tweetJSON), 24*time.Hour).Err()
	if err != nil {
		log.Printf("❌ Error guardando tweet JSON: %v", err)
	}

	// 2. Guardar en lista de IDs por municipio
	err = rdb.LPush(ctx, fmt.Sprintf("tweets:%s", tweet.Municipality), id).Err()
	if err != nil {
		log.Printf("❌ Error guardando en lista tweets:%s: %v", tweet.Municipality, err)
	}

	// 3. Incrementar contador
	err = rdb.Incr(ctx, fmt.Sprintf("count:%s", tweet.Municipality)).Err()
	if err != nil {
		log.Printf("❌ Error incrementando contador: %v", err)
	}

	// 4. Guardar temperatura en lista (para análisis)
	err = rdb.LPush(ctx, fmt.Sprintf("temperatures:%s", tweet.Municipality), int64(tweet.Temperature)).Err()
	if err != nil {
		log.Printf("❌ Error guardando temperatura: %v", err)
	}

	// 5. Guardar humedad en lista (para análisis)
	err = rdb.LPush(ctx, fmt.Sprintf("humidity:%s", tweet.Municipality), int64(tweet.Humidity)).Err()
	if err != nil {
		log.Printf("❌ Error guardando humedad: %v", err)
	}

	// 6. Guardar clima en contador (para distribución)
	err = rdb.Incr(ctx, fmt.Sprintf("weather:%s:%s", tweet.Municipality, tweet.Weather)).Err()
	if err != nil {
		log.Printf("❌ Error guardando clima: %v", err)
	}

	log.Printf("✓ Tweet #%d: %s (T:%d°C, H:%d%%) → Valkey",
		count, tweet.Municipality, tweet.Temperature, tweet.Humidity)

	response := ApiResponse{
		Status:  "success",
		Message: "Guardado en Valkey",
		ID:      id,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// Handler para obtener estadísticas
func handleStats(w http.ResponseWriter, r *http.Request) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Obtener contadores por municipio
	chinautlaCmd := rdb.Get(ctx, "count:chinautla")
	mixcoCmd := rdb.Get(ctx, "count:mixco")
	guatemalaCmd := rdb.Get(ctx, "count:guatemala")
	amatitlanCmd := rdb.Get(ctx, "count:amatitlan")

	response := map[string]interface{}{
		"total_processed": atomic.LoadInt64(&processed),
		"counts_by_municipality": map[string]string{
			"chinautla": chinautlaCmd.Val(),
			"mixco":     mixcoCmd.Val(),
			"guatemala": guatemalaCmd.Val(),
			"amatitlan": amatitlanCmd.Val(),
		},
		"service":   "Go Deployment 1 (Valkey Writer)",
		"timestamp": time.Now().Unix(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
}

func handleReady(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"ready":     true,
		"processed": atomic.LoadInt64(&processed),
	})
}

func handleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"service":      "Go Deployment 1 - Valkey Writer",
		"version":      "2.0.0",
		"municipality": "chinautla",
		"endpoints": map[string]string{
			"POST /api/weather": "Recibir y almacenar tweets",
			"GET /stats":        "Obtener estadísticas",
			"GET /health":       "Health check",
		},
	})
}

func main() {
	// Inicializar Valkey
	if err := initRedis(); err != nil {
		log.Fatalf("❌ Error inicializando Redis: %v", err)
	}
	defer rdb.Close()

	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("🚀 Go Deployment 1 (Valkey Writer) iniciando en puerto %s", port)
	log.Printf("📍 Municipio: Chinautla")

	http.HandleFunc("/", handleRoot)
	http.HandleFunc("/api/weather", handleWeatherPost)
	http.HandleFunc("/stats", handleStats)
	http.HandleFunc("/health", handleHealth)
	http.HandleFunc("/ready", handleReady)

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

	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatalf("❌ Error: %v", err)
	}

	log.Println("✓ Servidor detenido")
}
