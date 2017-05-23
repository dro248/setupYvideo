#!/bin/bash

default=""
force_clone=""
attach=""
travis=""
test_local=""
ayamel_dir=""
git_dir=${GITDIR:-~/Documents/GitHub}
compose_override_file=""
dev_compose_file="docker-compose.dev.yml"
production_compose_file="docker-compose.production.yml"
test_compose_file="docker-compose.test.yml"
repos=(Ayamel Ayamel.js EditorWidgets subtitle-timeline-editor TimedText)
remotes=(https://github.com/byu-odh/Ayamel
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
    echo '  [--attach      | -a]    Attach to the yvideo container'
    echo
    echo
    echo 'Required Params (One of the following. The last given option will be used if multiple are provided):'
    echo
    echo '  [--production  | -p]    Use the production docker-compose override file.'
    echo '  [--dev         | -d]    Use the development docker-compose override file.'
    echo '  [--test        | -t]    Use the dev docker-compose override file.'
    echo '                          Use volumes and run tests locally'
    echo '  [--tavis           ]    Use the testing docker-compose override file.'
    echo '                          Travis specific setup'
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
        elif [[ "$opt" = "--travis" ]]; then
            compose_override_file="$test_compose_file"
            travis=true
        elif [[ "$opt" = "--test" ]] || [[ "$opt" = "-t" ]]; then
            compose_override_file="$dev_compose_file"
            test_local=true
        elif [[ "$opt" = "--help" ]] || [[ "$opt" = "-h" ]]; then
            usage && exit
        elif [[ "$opt" = "--attach" ]] || [[ "$opt" = "-a" ]]; then
            attach=true
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
        if [[ -z "$default" ]]; then
            read -r -p "Enter path to $repo (default: ${dir_name:-$git_dir}/$repo): " user_dir
        else
            user_dir=""
        fi
        if [[ -z "$user_dir" ]]; then
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

    # set command which will run in the container
    if [[ -n "$test_local" ]]; then
       sed -i.bkp 's/\["sbt", "run"\]/\["sbt", "test"\]/' docker-compose.dev.yml
    else
       sed -i.bkp 's/\["sbt", "test"\]/\["sbt", "run"\]/' docker-compose.dev.yml
    fi
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

# Clone Dockerfile directories
clone_docker_repo () {

    # path of this script
    scriptpath="$( cd "$(dirname "$0")" ; pwd -P )"

    # check whether we are running in travis
    if [[ -z "$travis" ]]; then
        if [[ -z "$GITDIR" ]]; then
            mkdir -p ~/Docker && cd ~/Docker
        else
            cd "$GITDIR"
        fi
    else
        # go into the folder where travis cloned ayamel
        # this script is in Ayamel/setup/setupYvideo when set up by travis
        # so we go back two directories
        echo "Travis Mode."
        ayamel_dir="$( cd "$scriptpath"; cd ../../; pwd -P )"
        cd "$ayamel_dir"
    fi
    echo
    echo "Cloning Dependencies..."

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
}

setup () {
    clone_docker_repo
        
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
    echo "Making space for database..."
    sudo service mysql stop
fi

# Run docker-compose file (within runAyamel directory)
echo
echo "Creating Database & App..."
sudo docker-compose -f docker-compose.yml -f "$compose_override_file" up -d
[[ -n "$attach" ]] && sudo docker attach runayamel_yvideo_1

