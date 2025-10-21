package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"sync"
	"time"

	amqp "github.com/rabbitmq/amqp091-go"
	"github.com/redis/go-redis/v9"
)

type WeatherTweet struct {
	Municipality int32 `json:"municipality"`
	Temperature  int32 `json:"temperature"`
	Humidity     int32 `json:"humidity"`
	Weather      int32 `json:"weather"`
}

func main() {
	log.Println("Starting RabbitMQ Consumer...")

	// Initialize RabbitMQ connection
	rabbitMQURL := os.Getenv("RABBITMQ_URL")
	if rabbitMQURL == "" {
		rabbitMQURL = "amqp://guest:guest@rabbitmq-service.weather-system.svc.cluster.local:5672/"
	}

	conn, err := amqp.Dial(rabbitMQURL)
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %v", err)
	}
	defer conn.Close()

	// Create channel
	ch, err := conn.Channel()
	if err != nil {
		log.Fatalf("Failed to open channel: %v", err)
	}
	defer ch.Close()

	// Declare queue
	q, err := ch.QueueDeclare(
		"weather-tweets",
		false,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		log.Fatalf("Failed to declare queue: %v", err)
	}

	// Consume messages
	msgs, err := ch.Consume(
		q.Name,
		"",
		true,
		false,
		false,
		false,
		nil,
	)
	if err != nil {
		log.Fatalf("Failed to register consumer: %v", err)
	}

	// Initialize Redis client
	redisURL := os.Getenv("REDIS_URL")
	if redisURL == "" {
		redisURL = "redis://valkey-service.weather-system.svc.cluster.local:6379"
	}

	opts, _ := redis.ParseURL(redisURL)
	rdb := redis.NewClient(opts)

	ctx := context.Background()
	defer rdb.Close()

	// Verify Redis connection
	_, err = rdb.Ping(ctx).Result()
	if err != nil {
		log.Fatalf("Failed to connect to Redis: %v", err)
	}

	log.Println("Connected to Redis successfully")

	// Channel for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt)

	var wg sync.WaitGroup
	wg.Add(1)

	go func() {
		defer wg.Done()
		for {
			select {
			case <-sigChan:
				log.Println("Shutting down consumer...")
				return
			case msg := <-msgs:
				processTweet(msg.Body, rdb, ctx)
			}
		}
	}()

	wg.Wait()
	log.Println("Consumer stopped")
}

func processTweet(body []byte, rdb *redis.Client, ctx context.Context) {
	var tweet WeatherTweet
	err := json.Unmarshal(body, &tweet)
	if err != nil {
		log.Printf("Failed to parse message: %v", err)
		return
	}

	log.Printf("Processing tweet: %+v", tweet)

	// Store in Redis with expiration
	key := "tweet:" + time.Now().Format("2006-01-02T15:04:05")
	rdb.Set(ctx, key, string(body), 24*time.Hour)

	// Update statistics
	municipalityMap := map[int32]string{
		1: "mixco",
		2: "guatemala",
		3: "amatitlan",
		4: "chinautla",
	}

	weatherMap := map[int32]string{
		1: "sunny",
		2: "cloudy",
		3: "rainy",
		4: "foggy",
	}

	municipality := municipalityMap[tweet.Municipality]
	weather := weatherMap[tweet.Weather]

	// Increment counters
	rdb.Incr(ctx, "stats:total_tweets")
	rdb.Incr(ctx, "stats:municipality:"+municipality)
	rdb.Incr(ctx, "stats:weather:"+weather)

	// Update temperature and humidity
	rdb.IncrByFloat(ctx, "stats:temperature_sum", float64(tweet.Temperature))
	rdb.IncrByFloat(ctx, "stats:humidity_sum", float64(tweet.Humidity))

	log.Printf("Tweet stored successfully from %s", municipality)
}
