#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_variables_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["vars_missing"]="The 'vars' section is missing in 'playbook.yml'."
  ["web_package_missing"]="The 'web_package' variable is not defined in 'playbook.yml'."
  ["html_content_missing"]="The 'html_content' variable is not defined in 'playbook.yml'."
  ["apt_no_variable"]="The 'apt' task does not use the 'web_package' variable."
  ["copy_no_variable"]="The 'copy' task does not use the 'html_content' variable."
  ["success"]="The playbook has been successfully refactored to use variables."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["vars_missing"]="La section 'vars' est absente dans 'playbook.yml'."
  ["web_package_missing"]="La variable 'web_package' n'est pas définie dans 'playbook.yml'."
  ["html_content_missing"]="La variable 'html_content' n'est pas définie dans 'playbook.yml'."
  ["apt_no_variable"]="La tâche 'apt' n'utilise pas la variable 'web_package'."
  ["copy_no_variable"]="La tâche 'copy' n'utilise pas la variable 'html_content'."
  ["success"]="Le playbook a été refactorisé avec succès pour utiliser des variables."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["vars_missing"]="Der 'vars'-Abschnitt fehlt in 'playbook.yml'."
  ["web_package_missing"]="Die Variable 'web_package' ist in 'playbook.yml' nicht definiert."
  ["html_content_missing"]="Die Variable 'html_content' ist in 'playbook.yml' nicht definiert."
  ["apt_no_variable"]="Die 'apt'-Aufgabe verwendet die Variable 'web_package' nicht."
  ["copy_no_variable"]="Die 'copy'-Aufgabe verwendet die Variable 'html_content' nicht."
  ["success"]="Das Playbook wurde erfolgreich um Variablen refaktoriert."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["vars_missing"]="La sección 'vars' no está en 'playbook.yml'."
  ["web_package_missing"]="La variable 'web_package' no está definida en 'playbook.yml'."
  ["html_content_missing"]="La variable 'html_content' no está definida en 'playbook.yml'."
  ["apt_no_variable"]="La tarea 'apt' no usa la variable 'web_package'."
  ["copy_no_variable"]="La tarea 'copy' no usa la variable 'html_content'."
  ["success"]="El playbook ha sido refactorizado exitosamente para usar variables."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["vars_missing"]="La sezione 'vars' manca in 'playbook.yml'."
  ["web_package_missing"]="La variabile 'web_package' non è definita in 'playbook.yml'."
  ["html_content_missing"]="La variabile 'html_content' non è definita in 'playbook.yml'."
  ["apt_no_variable"]="Il compito 'apt' non usa la variabile 'web_package'."
  ["copy_no_variable"]="Il compito 'copy' non usa la variabile 'html_content'."
  ["success"]="Il playbook è stato rifattorizzato con successo per usare variabili."
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

# Check if 'vars' section exists
if ! grep -q "vars:" "playbook.yml"; then
  echo "$(get_message vars_missing)"
  exit 1
fi

# Check if 'web_package' variable is defined
if ! grep -q "web_package:" "playbook.yml"; then
  echo "$(get_message web_package_missing)"
  exit 1
fi

# Check if 'html_content' variable is defined
if ! grep -q "html_content:" "playbook.yml"; then
  echo "$(get_message html_content_missing)"
  exit 1
fi

# Function to extract a task block and check for a variable
check_task_for_variable() {
  local task_start_marker="$1"
  local variable_name="$2"
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

  # Check if the variable is used in the task content
  if ! echo "$task_content" | grep -q "{{.*${variable_name}.*}}"; then
    echo "$(get_message $error_key)"
    exit 1
  fi
}

# Check if 'apt' task uses 'web_package'
check_task_for_variable "ansible.builtin.apt:" "web_package" "apt_no_variable"

# Check if 'copy' task uses 'html_content'
check_task_for_variable "ansible.builtin.copy:" "html_content" "copy_no_variable"

# If all checks pass
echo "{\"result\": \"0\"}"