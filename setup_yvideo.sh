#!/bin/bash

default=""
force_clone=""
git_dir=${GITDIR:-~/Documents/GitHub}
compose_override_file=""
dev_compose_file="docker-compose.dev.yml"
production_compose_file="docker-compose.production.yml"
test_compose_file="docker-compose.test.yml"
repos=(Ayamel Ayamel.js EditorWidgets subtitle-timeline-editor TimedText)
remotes=(https://github.com/byu-odh/Ayamel.js
        https://github.com/byu-odh/Ayamel
        https://github.com/byu-odh/EditorWidgets
        https://github.com/byu-odh/subtitle-timeline-editor
        https://github.com/byu-odh/TimedText)

usage () {
    echo 'Optional Params:'
    echo
    echo '  [--default     | -e]    Accept the default repository locations '
    echo "                          Used for: ${repos[@]}"
    echo '                          (default is $GITDIR or ~/Documents/GitHub for everything)'
    echo '  [--force-clone | -f]    Overwrite the yvideo docker repository (you will lose changes)'
    echo '  [--help        | -h]    Show this dialog'
    echo
    echo
    echo 'Required Params (One of the following. The last given option will be used if multiple are provided):'
    echo
    echo '  [--production  | -p]    Use the production docker-compose override file.'
    echo '  [--dev         | -d]    Use the development docker-compose override file.'
    echo '  [--test        | -t]    Use the testing docker-compose override file.'
}

# Optional Params
#   [--default | -e]        Accept the default repository locations 
#                           (default is $GITDIR or ~/Documents/GitHub for everything)
#   [--force-clone | -f]    Overwrite the yvideo docker repository (you will lose changes to it
# Required (One of the following. The last given option will be used)
#   [--production  | -p]    Use the production docker-compose override file.
#   [--dev         | -d]    Use the development docker-compose override file.
#   [--test        | -t]    Use the testing docker-compose override file.
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
        elif [[ "$opt" = "--help" ]] || [[ "$opt" = "-h" ]]; then
            usage && exit
        fi
    done

    if [[ -z "$compose_override_file" ]]; then
        echo "[Error]: No mode specified"
        echo
        usage
        exit 1
    fi

}

compose_dev () {
    # setting up volumes
    for repo in "${repos[@]}"; do
        echo "repo: $repo"
        if [[ -z "$default" ]]; then
            read -r -p "Enter path to $repo (default: ${dir_name:-$git_dir}/$repo): " user_dir
        else
            user_dir=""
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

compose_test () {
    # clone the dependencies
    for repo in "${remotes[@]}"; do
        git clone "$repo" &> /dev/null
    done
}

compose_production () {
    echo "Compose Production Not Implemented"
    exit
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
    cd runAyamel

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
sudo docker-compose -f docker-compose.yml -f "$compose_override_file" up -d

