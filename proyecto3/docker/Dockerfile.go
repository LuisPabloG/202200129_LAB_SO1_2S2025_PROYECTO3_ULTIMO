FROM golang:1.21-alpine as builder

WORKDIR /app
COPY . .

RUN go mod download
RUN go build -o processor main.go

FROM alpine:latest

WORKDIR /app
COPY --from=builder /app/processor /app/processor

ENV HOST=0.0.0.0
ENV PORT=8081

EXPOSE 8081

CMD ["/app/processor"]
