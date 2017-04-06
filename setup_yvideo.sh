#!/bin/bash

# Create Docker directory (if doesn't exist)
echo "1. Making Directories..."
cd ~
mkdir -p Docker/ && cd Docker

# Clone Dockerfile directories
echo
echo "2. Cloning Dependencies..."
git clone git@github.com:dro248/ayamelDBDockerfile

git clone git@github.com:dro248/AyamelDockerfile
cd AyamelDockerfile/; git checkout dev; cd ..;

git clone git@github.com:dro248/runAyamel
cd runAyamel; git checkout dev;


# Get Ayamel path dir
read -r -p "Enter path to Ayamel (default: ~/Documents/GitHub/Ayamel):" ayameldir
if [[ -z $ayameldir ]]; then
  ayameldir="~/Documents/GitHub/Ayamel"
fi

# Get dependencies path dir
read -r -p "Enter path to Ayamel (default: /var/www/html):" dependenciesdir
if [[ -z $dependenciesdir ]]; then
  dependenciesdir="/var/www/html"
fi

# Insert $USER into runAyamel/docker-compose.yml file
replace "{{APP}}" "$ayameldir" -- docker-compose.yml
replace "{{DEPS}}" "$dependenciesdir" -- docker-compose.yml
cd ..;


# Turn off any other mysql database
echo
echo "4. Making space for database..."
sudo service mysql stop

# Run docker-compose file (within runAyamel directory)
echo
echo "5. Creating Database & App..."
cd runAyamel
sudo docker-compose up
