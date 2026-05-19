#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_user_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["wrong_hosts"]="The playbook does not target 'localhost'."
  ["become_missing"]="The 'become' directive is missing in 'playbook.yml'."
  ["user_task_missing"]="The 'ansible.builtin.user' task to add 'Alice' is missing in 'playbook.yml'."
  ["user_wrong_name"]="The 'ansible.builtin.user' task does not specify 'Alice' as the user name."
  ["alice_not_created"]="The user 'Alice' does not exist on the system."
  ["success"]="The playbook correctly adds user 'Alice' with 'become', and the user exists."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["wrong_hosts"]="Le playbook ne cible pas 'localhost'."
  ["become_missing"]="La directive 'become' est absente dans 'playbook.yml'."
  ["user_task_missing"]="La tâche 'ansible.builtin.user' pour ajouter 'Alice' est absente dans 'playbook.yml'."
  ["user_wrong_name"]="La tâche 'ansible.builtin.user' ne spécifie pas 'Alice' comme nom d'utilisateur."
  ["alice_not_created"]="L'utilisateur 'Alice' n'existe pas sur le système."
  ["success"]="Le playbook ajoute correctement l'utilisateur 'Alice' avec 'become', et l'utilisateur existe."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["wrong_hosts"]="Das Playbook zielt nicht auf 'localhost' ab."
  ["become_missing"]="Die Direktive 'become' fehlt in 'playbook.yml'."
  ["user_task_missing"]="Die Aufgabe 'ansible.builtin.user' zum Hinzufügen von 'Alice' fehlt in 'playbook.yml'."
  ["user_wrong_name"]="Die Aufgabe 'ansible.builtin.user' gibt 'Alice' nicht als Benutzernamen an."
  ["alice_not_created"]="Der Benutzer 'Alice' existiert nicht auf dem System."
  ["success"]="Das Playbook fügt den Benutzer 'Alice' mit 'become' korrekt hinzu, und der Benutzer existiert."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["wrong_hosts"]="El playbook no apunta a 'localhost'."
  ["become_missing"]="La directiva 'become' no está en 'playbook.yml'."
  ["user_task_missing"]="La tarea 'ansible.builtin.user' para añadir a 'Alice' no está en 'playbook.yml'."
  ["user_wrong_name"]="La tarea 'ansible.builtin.user' no especifica 'Alice' como nombre de usuario."
  ["alice_not_created"]="El usuario 'Alice' no existe en el sistema."
  ["success"]="El playbook añade correctamente al usuario 'Alice' con 'become', y el usuario existe."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["wrong_hosts"]="Il playbook non punta a 'localhost'."
  ["become_missing"]="La direttiva 'become' non è presente in 'playbook.yml'."
  ["user_task_missing"]="Il compito 'ansible.builtin.user' per aggiungere 'Alice' non è presente in 'playbook.yml'."
  ["user_wrong_name"]="Il compito 'ansible.builtin.user' non specifica 'Alice' come nome utente."
  ["alice_not_created"]="L'utente 'Alice' non esiste sul sistema."
  ["success"]="Il playbook aggiunge correttamente l'utente 'Alice' con 'become', e l'utente esiste."
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

# Check if the 'become' directive is present
if ! grep -q "become: yes" "playbook.yml"; then
  echo "$(get_message become_missing)"
  exit 1
fi

# Check if 'ansible.builtin.user' task exists and targets 'Alice'
check_task_for_parameter "ansible.builtin.user:" "name: Alice" "user_task_missing"

# Check if user 'Alice' exists on the system
if ! id "Alice" >/dev/null 2>&1; then
  echo "$(get_message alice_not_created)"
  exit 1
fi

# If all checks pass
echo "{\"result\": \"0\"}"