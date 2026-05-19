#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_collection_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["collection_not_installed"]="The 'community.general' collection is not installed."
  ["timezone_task_missing"]="The 'community.general.timezone' task is missing in 'playbook.yml'."
  ["timezone_wrong_value"]="The 'community.general.timezone' task does not set the timezone to 'UTC'."
  ["apt_task_missing"]="The 'ansible.builtin.apt' task for installing 'vim' is missing."
  ["success"]="The 'community.general' collection is installed and the playbook uses it correctly."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["collection_not_installed"]="La collection 'community.general' n'est pas installée."
  ["timezone_task_missing"]="La tâche 'community.general.timezone' est absente dans 'playbook.yml'."
  ["timezone_wrong_value"]="La tâche 'community.general.timezone' ne définit pas le fuseau horaire sur 'UTC'."
  ["apt_task_missing"]="La tâche 'ansible.builtin.apt' pour installer 'vim' est absente."
  ["success"]="La collection 'community.general' est installée et le playbook l'utilise correctement."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["collection_not_installed"]="Die Sammlung 'community.general' ist nicht installiert."
  ["timezone_task_missing"]="Die Aufgabe 'community.general.timezone' fehlt in 'playbook.yml'."
  ["timezone_wrong_value"]="Die Aufgabe 'community.general.timezone' setzt die Zeitzone nicht auf 'UTC'."
  ["apt_task_missing"]="Die Aufgabe 'ansible.builtin.apt' zum Installieren von 'vim' fehlt."
  ["success"]="Die Sammlung 'community.general' ist installiert und das Playbook verwendet sie korrekt."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["collection_not_installed"]="La colección 'community.general' no está instalada."
  ["timezone_task_missing"]="La tarea 'community.general.timezone' no está en 'playbook.yml'."
  ["timezone_wrong_value"]="La tarea 'community.general.timezone' no establece la zona horaria en 'UTC'."
  ["apt_task_missing"]="La tarea 'ansible.builtin.apt' para instalar 'vim' no está presente."
  ["success"]="La colección 'community.general' está instalada y el playbook la usa correctamente."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["collection_not_installed"]="La collezione 'community.general' non è installata."
  ["timezone_task_missing"]="Il compito 'community.general.timezone' non è presente in 'playbook.yml'."
  ["timezone_wrong_value"]="Il compito 'community.general.timezone' non imposta il fuso orario su 'UTC'."
  ["apt_task_missing"]="Il compito 'ansible.builtin.apt' per installare 'vim' non è presente."
  ["success"]="La collezione 'community.general' è installata e il playbook la usa correttamente."
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

# Check if 'community.general' collection is installed
if ! ansible-galaxy collection list | grep -q "community.general"; then
  echo "$(get_message collection_not_installed)"
  exit 1
fi

# Check if 'community.general.timezone' task exists and sets timezone to 'UTC'
check_task_for_parameter "community.general.timezone:" "name: UTC" "timezone_task_missing"
# Note: Since we already checked for the task's existence, we refine the error message for the value check
if ! grep -A 10 "community.general.timezone:" "playbook.yml" | grep -q "name: UTC"; then
  echo "$(get_message timezone_wrong_value)"
  exit 1
fi

# Check if 'ansible.builtin.apt' task exists and installs 'vim'
check_task_for_parameter "ansible.builtin.apt:" "name: vim" "apt_task_missing"

# If all checks pass
echo "{\"result\": \"0\"}"