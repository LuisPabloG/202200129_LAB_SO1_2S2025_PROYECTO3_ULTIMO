package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"sync"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	"github.com/redis/go-redis/v9"
)

type WeatherTweet struct {
	Municipality int32 `json:"municipality"`
	Temperature  int32 `json:"temperature"`
	Humidity     int32 `json:"humidity"`
	Weather      int32 `json:"weather"`
}

type WeatherStats struct {
	Count                int64            `json:"count"`
	AvgTemperature       float64          `json:"avg_temperature"`
	AvgHumidity          float64          `json:"avg_humidity"`
	LastUpdated          string           `json:"last_updated"`
	TweetsByMunicipality map[string]int64 `json:"tweets_by_municipality"`
	TweetsByWeather      map[string]int64 `json:"tweets_by_weather"`
}

func main() {
	log.Println("Starting Kafka Consumer...")

	// Initialize Kafka consumer
	kafkaBrokers := os.Getenv("KAFKA_BROKERS")
	if kafkaBrokers == "" {
		kafkaBrokers = "kafka-broker-0.kafka-broker-headless.weather-system.svc.cluster.local:9092"
	}

	consumer, err := kafka.NewConsumer(&kafka.ConfigMap{
		"bootstrap.servers": kafkaBrokers,
		"group.id":          "weather-consumer-group",
		"auto.offset.reset": "earliest",
	})
	if err != nil {
		log.Fatalf("Failed to create consumer: %v", err)
	}
	defer consumer.Close()

	// Subscribe to topic
	err = consumer.SubscribeTopics([]string{"weather-tweets"}, nil)
	if err != nil {
		log.Fatalf("Failed to subscribe: %v", err)
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
			default:
				msg, err := consumer.ReadMessage(time.Second)
				if err == nil {
					processTweet(msg, rdb, ctx)
				}
			}
		}
	}()

	wg.Wait()
	log.Println("Consumer stopped")
}

func processTweet(msg *kafka.Message, rdb *redis.Client, ctx context.Context) {
	var tweet WeatherTweet
	err := json.Unmarshal(msg.Value, &tweet)
	if err != nil {
		log.Printf("Failed to parse message: %v", err)
		return
	}

	log.Printf("Processing tweet: %+v", tweet)

	// Store in Redis with expiration
	key := "tweet:" + time.Now().Format("2006-01-02T15:04:05")
	rdb.Set(ctx, key, string(msg.Value), 24*time.Hour)

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
