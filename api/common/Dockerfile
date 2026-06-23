# Use an official Golang runtime as a base image (Updated to 1.26)
FROM golang:1.26-alpine AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the go.mod file to the workspace
COPY go.mod ./

# Copy the entire project into the container early 
# (Required for 'go mod tidy' to see which packages your code actually uses)
COPY . .

# Download dependencies and generate go.sum
RUN go mod tidy

# Build the Go application 
RUN go build -o myapp

# Start a new stage from scratch
FROM alpine:latest

# Install mongodb client 
RUN apk --no-cache add mongodb-tools 

# Set the working directory inside the container
WORKDIR /app

# Copy the built binary from the builder stage
COPY --from=builder /app/myapp .

# Copy the .env file -- Skipping in case it is not present in the project directory using the [v] flag to avoid build failure
COPY .en[v] .

# Expose the port on which the application will run 
EXPOSE 9000 

# Command to run the executable
CMD ["./myapp"]