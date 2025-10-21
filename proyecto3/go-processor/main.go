package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
)

type WeatherTweet struct {
	Municipality string `json:"municipality"`
	Temperature  int    `json:"temperature"`
	Humidity     int    `json:"humidity"`
	Weather      string `json:"weather"`
}

type ProcessorResponse struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}

var tweetCount = 0

func main() {
	host := os.Getenv("HOST")
	if host == "" {
		host = "0.0.0.0"
	}
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	addr := fmt.Sprintf("%s:%s", host, port)

	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{
			"status":  "ok",
			"message": "Go processor is running",
		})
	})

	http.HandleFunc("/process", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var tweet WeatherTweet
		if err := json.NewDecoder(r.Body).Decode(&tweet); err != nil {
			http.Error(w, "Invalid JSON", http.StatusBadRequest)
			return
		}

		tweetCount++
		log.Printf("Tweet procesado #%d: %+v\n", tweetCount, tweet)

		// Aquí se conectaría con Kafka/RabbitMQ
		// Por ahora solo almacenamos en memoria

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(ProcessorResponse{
			Status:  "processed",
			Message: fmt.Sprintf("Tweet #%d almacenado", tweetCount),
		})
	})

	http.HandleFunc("/stats", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"total_processed": tweetCount,
			"status":          "running",
		})
	})

	fmt.Printf("🚀 Procesador Go iniciando en %s\n", addr)
	if err := http.ListenAndServe(addr, nil); err != nil {
		log.Fatal(err)
	}
}
