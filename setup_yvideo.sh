#!/bin/bash

default=""
force_clone=""
git_dir=${GITDIR:-~/Documents/GitHub}
compose_override_file=""
dev_compose_file="docker-compose.dev.yml"
production_compose_file="docker-compose.production.yml"
test_compose_file="docker-compose.test.yml"

dirname () { 
    test -n "$1" || return 0
    local x="$1"; while :; do case "$x" in */) x="${x%?}";; *) break;; esac; done
    [ -n "$x" ] || { echo /; return; }
    set -- "$x"; x="${1%/*}"
    case "$x" in "$1") x=.;; "") x=/;; esac
    printf '%s\n' "$x"
}

options () {
    for opt in "$@"; do
        if [[ "$opt" = "--default" ]] || [[ "$opt" = "-e" ]]; then
            default="true"
        elif [[ "$opt" = "--force-clone" ]] || [[ "$opt" = "-f" ]]; then
            force_clone="true"
        elif [[ "$opt" = "--dev" ]] || [[ "$opt" = "-d" ]]; then
            compose_override_file="$dev_compose_file"
        elif [[ "$opt" = "--production" ]] || [[ "$opt" = "-p" ]]; then
            compose_override_file="$production_compose_file"
        elif [[ "$opt" = "--test" ]] || [[ "$opt" = "-t" ]]; then
            compose_override_file="$test_compose_file"
        fi
    done
}

compose_dev () {
    repos=(Ayamel Ayamel.js EditorWidgets subtitle-timeline-editor TimedText)

    # setting up volumes
    for repo in "${repos[@]}"; do
        echo "repo: $repo"
        if [[ -z "$default" ]]; then
            read -r -p "Enter path to $repo (default: ${dir_name:-$git_dir}/$repo): " user_dir
        fi
        if [[ -z "$user_dir" ]]; then
            echo "repo: $repo"
            user_dir="$git_dir/$repo"
        else
            # expand the path
            if [[ -d "$user_dir" ]]; then
                user_dir="$( cd "$user_dir"; pwd -P )"
                dir_name=$(dirname "$user_dir")
            else
                echo "$user_dir does not exist."
                user_dir="$dir_name/$repo"
            fi
        fi
        echo "Using $user_dir for $repo."
        sed -i.bkp "s_"{{$repo}}"_"$user_dir"_" docker-compose.dev.yml
    done
}

setup () {
    # Create Docker directory (if doesn't exist)
    echo "1. Making Directories..."
    if [[ -z "$GITDIR" ]]; then
        mkdir -p ~/Docker && cd ~/Docker
    else
        cd $GITDIR
    fi

    # Clone Dockerfile directories
    echo
    echo "2. Cloning Dependencies..."

    if [[ -n "$force_clone" ]]; then
        if [[ -d runAyamel ]]; then
            # TODO: check for changes
            echo "Removing runAyamel"
            rm -rf runAyamel
        else
            echo "runAyamel repo not found"
        fi
    fi

    git clone https://github.com/dro248/runAyamel &> /dev/null
    cd runAyamel; git checkout dev &> /dev/null

    if [[ "$compose_override_file" = "$dev_compose_file" ]]; then
        compose_dev
    elif [[ "$compose_override_file" = "$production_compose_file" ]]; then
        compose_production
    elif [[ "$compose_override_file" = "$test_compose_file" ]]; then
        compose_test
    fi
}

options "$@"
setup

# Turn off any other mysql database
if [[ -n $(pgrep mysql) ]]; then
    echo
    echo "4. Making space for database..."
    sudo service mysql stop
fi

# Run docker-compose file (within runAyamel directory)
echo
echo "5. Creating Database & App..."
sudo docker-compose -f docker-compose.yml -f "$compose_override_file" up

