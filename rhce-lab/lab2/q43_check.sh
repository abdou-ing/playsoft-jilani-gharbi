#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_nginx_localhost_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["wrong_hosts"]="The playbook does not target 'localhost'."
  ["apt_task_missing"]="The 'ansible.builtin.apt' task to install 'nginx' is missing in 'playbook.yml'."
  ["apt_wrong_package"]="The 'ansible.builtin.apt' task does not specify 'nginx' as the package."
  ["nginx_not_installed"]="The 'nginx' package is not installed on the system."
  ["success"]="The playbook correctly installs 'nginx' on 'localhost', and nginx is installed."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["wrong_hosts"]="Le playbook ne cible pas 'localhost'."
  ["apt_task_missing"]="La tâche 'ansible.builtin.apt' pour installer 'nginx' est absente dans 'playbook.yml'."
  ["apt_wrong_package"]="La tâche 'ansible.builtin.apt' ne spécifie pas 'nginx' comme paquet."
  ["nginx_not_installed"]="Le paquet 'nginx' n'est pas installé sur le système."
  ["success"]="Le playbook installe correctement 'nginx' sur 'localhost', et nginx est installé."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["wrong_hosts"]="Das Playbook zielt nicht auf 'localhost' ab."
  ["apt_task_missing"]="Die Aufgabe 'ansible.builtin.apt' zum Installieren von 'nginx' fehlt in 'playbook.yml'."
  ["apt_wrong_package"]="Die Aufgabe 'ansible.builtin.apt' gibt 'nginx' nicht als Paket an."
  ["nginx_not_installed"]="Das Paket 'nginx' ist nicht auf dem System installiert."
  ["success"]="Das Playbook installiert 'nginx' korrekt auf 'localhost', und nginx ist installiert."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["wrong_hosts"]="El playbook no apunta a 'localhost'."
  ["apt_task_missing"]="La tarea 'ansible.builtin.apt' para instalar 'nginx' no está en 'playbook.yml'."
  ["apt_wrong_package"]="La tarea 'ansible.builtin.apt' no especifica 'nginx' como paquete."
  ["nginx_not_installed"]="El paquete 'nginx' no está instalado en el sistema."
  ["success"]="El playbook instala correctamente 'nginx' en 'localhost', y nginx está instalado."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["wrong_hosts"]="Il playbook non punta a 'localhost'."
  ["apt_task_missing"]="Il compito 'ansible.builtin.apt' per installare 'nginx' non è presente in 'playbook.yml'."
  ["apt_wrong_package"]="Il compito 'ansible.builtin.apt' non specifica 'nginx' come pacchetto."
  ["nginx_not_installed"]="Il pacchetto 'nginx' non è installato sul sistema."
  ["success"]="Il playbook installa correttamente 'nginx' su 'localhost', e nginx è installato."
)

# List of supported languages
supported_languages=("en" "fr" "de" "es" "it")

# Check if the provided language is supported
if [[ ! " ${supported_languages[@]} " =~ " $lang " ]]; then
  lang="en"  # Default to English if the language is not supported
fi

# Select the appropriate set of messages based on the selected language
case "$lang" in
  "fr") messages=("${!messages_fr[@]}") ;;
  "de") messages=("${!messages_de[@]}") ;;
  "es") messages=("${!messages_es[@]}") ;;
  "it") messages=("${!messages_it[@]}") ;;
  *) messages=("${!messages_en[@]}") ;; # Default to English
esac

# Function to retrieve message by key
get_message() {
  local key=$1
  # Use nameref to dynamically access the correct messages array
  declare -n msg_array="messages_$lang"
  
  # Check if the key exists in the array
  if [[ -n "${msg_array[$key]}" ]]; then
    echo "{\"result\": \"${msg_array[$key]}\"}"
  else
    echo "{\"result\": \"Message key '$key' not found in language '$lang'\"}"
  fi
}

# Function to extract a task block and check for a parameter
check_task_for_parameter() {
  local task_start_marker="$1"
  local param_pattern="$2"
  local error_key="$3"
  local start_line_num
  local end_line_num
  local task_content

  # Find the line number where the task starts
  start_line_num=$(grep -n "$task_start_marker" "playbook.yml" | cut -d: -f1)
  if [[ -z "$start_line_num" ]]; then
    echo "$(get_message $error_key)"
    exit 1
  fi

  # Find the line number of the next task or end of tasks section
  end_line_num=$(tail -n +"$start_line_num" "playbook.yml" | grep -n -m 1 "^\s*- name:" | cut -d: -f1)
  if [[ -z "$end_line_num" ]]; then
    # If no next task, take the rest of the file
    task_content=$(tail -n +"$start_line_num" "playbook.yml")
  else
    # Otherwise, take lines up to the next task
    end_line_num=$((start_line_num + end_line_num - 2))
    task_content=$(sed -n "${start_line_num},${end_line_num}p" "playbook.yml")
  fi

  # Check if the parameter is present in the task content
  if ! echo "$task_content" | grep -q "$param_pattern"; then
    echo "$(get_message $error_key)"
    exit 1
  fi
}

# Check if the project directory exists
if [[ ! -d "$project_dir" ]]; then
  echo "$(get_message dir_not_found)"
  exit 1
fi

cd "$project_dir"

# Check if 'playbook.yml' exists
if [[ ! -f "playbook.yml" ]]; then
  echo "$(get_message playbook_missing)"
  exit 1
fi

# Check if the playbook targets 'localhost'
if ! grep -q "hosts: localhost" "playbook.yml"; then
  echo "$(get_message wrong_hosts)"
  exit 1
fi

# Check if 'ansible.builtin.apt' task exists and targets 'nginx'
check_task_for_parameter "ansible.builtin.apt:" "name: nginx" "apt_task_missing"

# Check if 'nginx' is actually installed on the system
if ! dpkg -l | grep -q "nginx"; then
  echo "$(get_message nginx_not_installed)"
  exit 1
fi

# If all checks pass
echo "{\"result\": \"0\"}"