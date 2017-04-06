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

# Insert $USER into runAyamel/docker-compose.yml file
replace "{{USER}}" "`echo $USER`" -- docker-compose.yml
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
