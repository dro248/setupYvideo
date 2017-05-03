#!/bin/bash

dirname(){ 
    test -n "$1" || return 0
    local x="$1"; while :; do case "$x" in */) x="${x%?}";; *) break;; esac; done
    [ -n "$x" ] || { echo /; return; }
    set -- "$x"; x="${1%/*}"
    case "$x" in "$1") x=.;; "") x=/;; esac
    printf '%s\n' "$x"
}

# Create Docker directory (if doesn't exist)
echo "1. Making Directories..."
pushd ~
mkdir -p Docker/ && cd Docker

git_dir=${GITDIR:-~/Documents/GitHub}

# Clone Dockerfile directories
echo
echo "2. Cloning Dependencies..."
git clone https://github.com/dro248/ayamelDBDockerfile &> /dev/null

git clone https://github.com/dro248/AyamelDockerfile &> /dev/null
cd AyamelDockerfile/; git checkout dev &> /dev/null; cd ..;

git clone https://github.com/dro248/runAyamel &> /dev/null
cd runAyamel; git checkout dev &> /dev/null; git checkout -- .

repos=(Ayamel Ayamel.js EditorWidgets subtitle-timeline-editor TimedText)

# Get Ayamel path dir
for repo in "${repos[@]}"; do
    read -r -p "Enter path to $repo (default: ${dir_name:-$git_dir}/$repo): " user_dir
    if [[ -z "$user_dir" ]]; then
        user_dir="$git_dir/$repo"
    else
        # expand the path
        if [[ -d "$user_dir" ]]; then
            user_dir="$( cd "$user_dir"; pwd -P )"
            dir_name=$(dirname "$user_dir")
        else
            user_dir="$git_dir/$repo"
        fi
    fi
    echo "Using $user_dir for $repo."
    echo
    sed -i.bkp "s_"{{$repo}}"_"$user_dir"_"  docker-compose.yml
done

cd ..

# Turn off any other mysql database
echo
echo "4. Making space for database..."
sudo service mysql stop

# Run docker-compose file (within runAyamel directory)
echo
echo "5. Creating Database & App..."
cd runAyamel
sudo docker-compose up

