#!/bin/bash

set -e

SUCCESS='\033[0;32m'
WARNING='\033[0;33m'
FAILURE='\033[0;31m'
BOLD='\033[1m'
OR='\033[0m' # Output Reset

function print_success {
  echo -e "${SUCCESS}$1${OR}"
}

function print_warning {
  echo -e "${WARNING}$1${OR}"
}

function print_failure {
  echo -e "${FAIL}$1${OR}"
}

function print_bold {
  echo -e "${BOLD}$1${OR}"
}

function parse_arguments() {
  # Default to latest version if no --pg-version argument is passed
  PG_VERSION="latest"

  # Default to current user if no --pg-user argument is passed
  PG_USER=$(whoami)

  # Ensure at least two arguments are passed (project_name and file_name)
  if [ "$#" -lt 2 ]; then
    echo -e "Usage: $0 [--pg-version=value] [--pg-user=value] project_name file_name" >&2
    exit 1
  fi

 # Parse all arguments except the last two (project_name and file_name)
  for arg in "${@:1:$#-2}"; do
    case "$arg" in
      --pg-user=*)
        PG_USER="${arg#*=}"
        ;;
      --pg-version=*)
        PG_VERSION="${arg#*=}"
        ;;
      *)
        echo "Unknown option: $arg" >&2
        exit 1
        ;;
    esac
  done

  # The second-to-last argument is the project_name
  PROJECT_NAME="$1"

  CONTAINER_NAME="${PROJECT_NAME}-development-template"
  VOLUME_NAME="${PROJECT_NAME}-development-template"
  DATABASE_NAME="${PROJECT_NAME}_development"

  # The last argument is the file_name
  FILE_NAME="$2"
}

function stop_container_if_running() {
  local container_name="$1"

  # Check if the container is running
  if [ "$(docker ps -q -f name=^"$container_name"$)" ]; then
    echo -n -e "Stopping container $(print_bold $container_name)\t\t\t"
    docker stop "$container_name" > /dev/null && print_success "done"
  else
    echo -e "Container $(print_bold $container_name) is not running\t\t$(print_warning "skipped")"
  fi
}

function delete_container_if_exists() {
  local container_name="$1"

  # Check if the container exists (whether it's running or stopped)
  if [ "$(docker ps -a -q -f name=^"$container_name"$)" ]; then
    echo -n -e  "Deleting container $(print_bold $container_name)\t\t\t"
    docker rm --volumes "$container_name" > /dev/null && print_success "done"
  else
    echo -e "Container $(print_bold $container_name) does not exist\t\t$(print_warning "skipped")"
  fi
}

function ensure_docker_volume() {
  local volume_name="$1"

  # Check if the volume exists
  if [ "$(docker volume ls -q -f name=^"$volume_name"$)" ]; then
    echo -n -e "Removing existing volume $(print_bold $volume_name)\t\t"
    docker volume rm "$volume_name" > /dev/null && print_success "done"
  fi

  # Create a new volume with the same name
  echo -n -e "Creating new volume $(print_bold $volume_name)\t\t\t"
  docker volume create "$volume_name" > /dev/null && print_success "done"
}

function run_container() {
  local container_name="$1"
  local database_name="$2"
  local volume_name="$3"

  echo -n -e "Starting container $(print_bold $container_name)\t\t\t"
  docker run --name ${container_name} \
    -p 15432:5432 \
    -e POSTGRES_USER=${PG_USER} \
    -e POSTGRES_DB=${database_name} \
    -e POSTGRES_HOST_AUTH_METHOD=trust \
    -v ${volume_name}:/var/lib/postgresql/data \
    -d postgres:${PG_VERSION} > /dev/null && print_success "done"
}

function load_dump() {
  local database_name="$1"

  echo -e "\tLoading ${FILE_NAME}..."
  echo -n -e "into $(print_bold $database_name)\t\t\t\t\t"
  psql -d ${database_name} \
    -h localhost \
    -p 15432 < ${FILE_NAME} > /dev/null
  print_success "done"
}

start_time=$(date +%s)

parse_arguments "$@"

stop_container_if_running ${CONTAINER_NAME}
delete_container_if_exists ${CONTAINER_NAME}
ensure_docker_volume ${VOLUME_NAME}
run_container ${CONTAINER_NAME} ${DATABASE_NAME} ${VOLUME_NAME}
sleep 5
load_dump ${DATABASE_NAME}

echo -e "\nDatabase $(print_bold ${DATABASE_NAME}) is running on port $(print_bold 15432)"

echo -e "\nWhat to do next:"
echo -e "1. Run migrations"
echo -e "2. Start Rails server"
echo -e "3. Change the data the way you want it to be in the template"
echo -e "4. Stop Rails server"
echo -e "5. Stop the database container with the command: $(print_bold "docker stop ${CONTAINER_NAME}")"
echo -e "6. Run $(print_bold "./bin/docker-db-use-template.sh ${PROJECT_NAME}") to use the template"

end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo -e "Elapsed time: $(print_bold $elapsed_time) seconds"
