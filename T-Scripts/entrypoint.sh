#!/bin/bash
sudo apt update -y
sudo apt install -y docker.io
sudo chmod 666 /var/run/docker.sock
sudo systemctl start docker
sudo usermod -aG docker ubuntu
sudo systemctl restart docker
# sudo apt install maven -y
# git clone https://github.com/nuruzzaman24x/jpetstore-6.git
# cd /jpetstore-6
# mv package
# docker build -t petsore .
# if you do not want to make image, then run readymade image
docker run -d -p 8080:8080 nuruzzaman24x/petsore
