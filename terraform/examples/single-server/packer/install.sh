#!/usr/bin/env bash

sudo apt-get update
sudo apt-get remove docker docker-engine docker.io
sudo apt install docker.io
sudo systemctl start docker
sudo apt-get install 
sudo git clone https://github.com/rykelley/spring-boot-app.git /var/www/html/app
