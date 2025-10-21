# Stage 1: Build
FROM golang:1.21-alpine as builder

WORKDIR /app

COPY src/go/go.mod .
COPY src/go/go.sum* .

RUN go mod download || true

COPY src/go ./

RUN CGO_ENABLED=1 GOOS=linux go build -o weather-processor ./api/processor.go

# Stage 2: Runtime
FROM alpine:latest

RUN apk add --no-cache ca-certificates

COPY --from=builder /app/weather-processor /usr/local/bin/

EXPOSE 8081 50051

CMD ["weather-processor"]
