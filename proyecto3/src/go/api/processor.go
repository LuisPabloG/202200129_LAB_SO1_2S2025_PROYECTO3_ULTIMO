package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"os/signal"
	"sync"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
	amqp "github.com/rabbitmq/amqp091-go"
	"google.golang.org/grpc"
)

func main() {
	log.Println("Starting Weather Processor API...")

	// Initialize Kafka producer
	kafkaProducer, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": os.Getenv("KAFKA_BROKERS"),
	})
	if err != nil {
		log.Printf("Failed to create Kafka producer: %v", err)
	}
	defer kafkaProducer.Close()

	// Initialize RabbitMQ connection
	rabbitMQURL := os.Getenv("RABBITMQ_URL")
	if rabbitMQURL == "" {
		rabbitMQURL = "amqp://guest:guest@localhost:5672/"
	}

	rabbitConn, err := amqp.Dial(rabbitMQURL)
	if err != nil {
		log.Printf("Failed to connect to RabbitMQ: %v", err)
	}
	defer rabbitConn.Close()

	// Create channels
	kafitab, err := rabbitConn.Channel()
	if err != nil {
		log.Printf("Failed to open RabbitMQ channel: %v", err)
	}
	defer kafitab.Close()

	// Start gRPC server
	lis, err := net.Listen("tcp", ":50051")
	if err != nil {
		log.Fatalf("Failed to listen: %v", err)
	}

	grpcServer := grpc.NewServer()
	server := &WeatherServiceServer{
		kafkaProducer: kafkaProducer,
		rabbitChannel: kafitab,
	}

	RegisterWeatherTweetServiceServer(grpcServer, server)

	go func() {
		log.Println("Starting gRPC server on :50051")
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("gRPC server failed: %v", err)
		}
	}()

	// Start REST API
	http.HandleFunc("/health", healthHandler)
	go func() {
		log.Println("Starting REST API on :8081")
		if err := http.ListenAndServe(":8081", nil); err != nil {
			log.Fatalf("REST API failed: %v", err)
		}
	}()

	// Wait for interrupt signal
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt)
	<-sigChan

	log.Println("Shutting down...")
	grpcServer.GracefulStop()
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	fmt.Fprintf(w, `{"status":"ok"}`)
}

type WeatherServiceServer struct {
	kafkaProducer *kafka.Producer
	rabbitChannel *amqp.Channel
	mu            sync.Mutex
	UnimplementedWeatherTweetServiceServer
}

func (s *WeatherServiceServer) SendTweet(ctx context.Context, req *WeatherTweetRequest) (*WeatherTweetResponse, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	log.Printf("Received tweet: Municipality=%d, Temp=%d, Humidity=%d, Weather=%d",
		req.Municipality, req.Temperature, req.Humidity, req.Weather)

	// Publish to Kafka
	topic := "weather-tweets"
	message := fmt.Sprintf(`{"municipality":%d,"temperature":%d,"humidity":%d,"weather":%d}`,
		req.Municipality, req.Temperature, req.Humidity, req.Weather)

	s.kafkaProducer.Produce(&kafka.Message{
		TopicPartition: kafka.TopicPartition{
			Topic:     &topic,
			Partition: kafka.PartitionAny,
		},
		Value: []byte(message),
	}, nil)

	// Publish to RabbitMQ
	q, _ := s.rabbitChannel.QueueDeclare("weather-tweets", false, false, false, false, nil)
	s.rabbitChannel.Publish("", q.Name, false, false, amqp.Publishing{
		ContentType: "application/json",
		Body:        []byte(message),
	})

	return &WeatherTweetResponse{
		Status: "processed",
	}, nil
}
