#!/bin/bash

# Install Docker and Git
sudo amazon-linux-extras install docker -y

# Start Docker service
sudo service docker start

# Build the Docker images
sudo docker build -t web-app . -f app/Dockerfile
sudo docker build -t my-nginx . -f nginx/Dockerfile

# Create a Docker network
sudo docker network create my-network

# Start the Docker containers
sudo docker run -d --name my-nginx --network my-network -p 80:80 my-nginx
sudo docker run -d --name web-app --network my-network web-app