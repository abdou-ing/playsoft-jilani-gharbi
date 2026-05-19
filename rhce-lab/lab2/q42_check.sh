#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_idempotency_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["command_module_used"]="The 'ansible.builtin.command' module is still used in 'playbook.yml'. It should be replaced."
  ["file_task_missing"]="The 'ansible.builtin.file' task to create '/tmp/myapp' is missing in 'playbook.yml'."
  ["file_wrong_path"]="The 'ansible.builtin.file' task does not target '/tmp/myapp'."
  ["file_not_directory"]="The 'ansible.builtin.file' task does not set 'state: directory'."
  ["success"]="The playbook has been successfully refactored to use the 'file' module idempotently."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["command_module_used"]="Le module 'ansible.builtin.command' est toujours utilisé dans 'playbook.yml'. Il doit être remplacé."
  ["file_task_missing"]="La tâche 'ansible.builtin.file' pour créer '/tmp/myapp' est absente dans 'playbook.yml'."
  ["file_wrong_path"]="La tâche 'ansible.builtin.file' ne cible pas '/tmp/myapp'."
  ["file_not_directory"]="La tâche 'ansible.builtin.file' ne définit pas 'state: directory'."
  ["success"]="Le playbook a été refactorisé avec succès pour utiliser le module 'file' de manière idempotente."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["command_module_used"]="Das Modul 'ansible.builtin.command' wird noch in 'playbook.yml' verwendet. Es sollte ersetzt werden."
  ["file_task_missing"]="Die Aufgabe 'ansible.builtin.file' zum Erstellen von '/tmp/myapp' fehlt in 'playbook.yml'."
  ["file_wrong_path"]="Die Aufgabe 'ansible.builtin.file' zielt nicht auf '/tmp/myapp' ab."
  ["file_not_directory"]="Die Aufgabe 'ansible.builtin.file' setzt nicht 'state: directory'."
  ["success"]="Das Playbook wurde erfolgreich um das Modul 'file' idempotent refaktoriert."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["command_module_used"]="El módulo 'ansible.builtin.command' todavía se usa en 'playbook.yml'. Debe ser reemplazado."
  ["file_task_missing"]="La tarea 'ansible.builtin.file' para crear '/tmp/myapp' no está en 'playbook.yml'."
  ["file_wrong_path"]="La tarea 'ansible.builtin.file' no apunta a '/tmp/myapp'."
  ["file_not_directory"]="La tarea 'ansible.builtin.file' no establece 'state: directory'."
  ["success"]="El playbook ha sido refactorizado exitosamente para usar el módulo 'file' de forma idempotente."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["command_module_used"]="Il modulo 'ansible.builtin.command' è ancora usato in 'playbook.yml'. Deve essere sostituito."
  ["file_task_missing"]="Il compito 'ansible.builtin.file' per creare '/tmp/myapp' non è presente in 'playbook.yml'."
  ["file_wrong_path"]="Il compito 'ansible.builtin.file' non punta a '/tmp/myapp'."
  ["file_not_directory"]="Il compito 'ansible.builtin.file' non imposta 'state: directory'."
  ["success"]="Il playbook è stato rifattorizzato con successo per usare il modulo 'file' in modo idempotente."
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

# Check if 'ansible.builtin.command' is still used
if grep -q "ansible.builtin.command:" "playbook.yml"; then
  echo "$(get_message command_module_used)"
  exit 1
fi

# Check if 'ansible.builtin.file' task exists and has correct parameters
check_task_for_parameter "ansible.builtin.file:" "path: /tmp/myapp" "file_task_missing"
check_task_for_parameter "ansible.builtin.file:" "state: directory" "file_not_directory"

# If all checks pass
echo "{\"result\": \"0\"}"