#!/usr/bin/env bash

sudo apt-get update -y
sudo apt-get remove docker docker-engine docker.io
sudo apt install docker.io
sudo systemctl start docker
sudo apt-get install openjdk-11-jdk
sudo apt-get install maven
sudo git clone https://github.com/rykelley/spring-boot-app.git /home/ubuntu
/home/ubuntu/ mvn -N io.takari:maven:wrapper
/home/ubuntu/ ./mvnw -Pprod clean verify
/home/ubuntu/ java -jar target/*.jar
