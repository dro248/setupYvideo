#!/bin/bash

# Create Docker directory (if doesn't exist)
echo "1. Making Directories..."
cd ~
mkdir -p Docker/ && cd Docker

# Clone Dockerfile directorys
echo
echo "2. Cloning Dependencies..."
git clone git@github.com:dro248/ayamelDBDockerfile
git clone git@github.com:dro248/AyamelDockerfile
git clone git@github.com:dro248/runAyamel

# Turn off any other mysql database
echo
echo "4. Making space for database..."
sudo service mysql stop

# Run docker-compose file (within runAyamel directory)
echo
echo "5. Creating Database & App..."
cd runAyamel
sudo docker-compose up
