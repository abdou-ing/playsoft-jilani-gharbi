#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_role_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["role_dir_missing"]="The 'roles/webserver' directory is missing."
  ["tasks_file_missing"]="The 'roles/webserver/tasks/main.yml' file is missing."
  ["playbook_no_role"]="The 'playbook.yml' does not use the 'webserver' role."
  ["install_task_missing"]="The task to install Apache is missing in 'roles/webserver/tasks/main.yml'."
  ["start_task_missing"]="The task to start Apache service is missing in 'roles/webserver/tasks/main.yml'."
  ["success"]="The tasks have been successfully refactored into the 'webserver' role."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["role_dir_missing"]="Le répertoire 'roles/webserver' est manquant."
  ["tasks_file_missing"]="Le fichier 'roles/webserver/tasks/main.yml' est manquant."
  ["playbook_no_role"]="Le 'playbook.yml' n'utilise pas le rôle 'webserver'."
  ["install_task_missing"]="La tâche pour installer Apache est absente dans 'roles/webserver/tasks/main.yml'."
  ["start_task_missing"]="La tâche pour démarrer le service Apache est absente dans 'roles/webserver/tasks/main.yml'."
  ["success"]="Les tâches ont été refactorisées avec succès dans le rôle 'webserver'."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["role_dir_missing"]="Das Verzeichnis 'roles/webserver' fehlt."
  ["tasks_file_missing"]="Die Datei 'roles/webserver/tasks/main.yml' fehlt."
  ["playbook_no_role"]="Das 'playbook.yml' verwendet nicht die Rolle 'webserver'."
  ["install_task_missing"]="Die Aufgabe zum Installieren von Apache fehlt in 'roles/webserver/tasks/main.yml'."
  ["start_task_missing"]="Die Aufgabe zum Starten des Apache-Dienstes fehlt in 'roles/webserver/tasks/main.yml'."
  ["success"]="Die Aufgaben wurden erfolgreich in die Rolle 'webserver' refaktoriert."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["role_dir_missing"]="El directorio 'roles/webserver' no está presente."
  ["tasks_file_missing"]="El archivo 'roles/webserver/tasks/main.yml' no está presente."
  ["playbook_no_role"]="El 'playbook.yml' no usa el rol 'webserver'."
  ["install_task_missing"]="La tarea para instalar Apache no está en 'roles/webserver/tasks/main.yml'."
  ["start_task_missing"]="La tarea para iniciar el servicio Apache no está en 'roles/webserver/tasks/main.yml'."
  ["success"]="Las tareas han sido refactorizadas exitosamente en el rol 'webserver'."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["role_dir_missing"]="La directory 'roles/webserver' manca."
  ["tasks_file_missing"]="Il file 'roles/webserver/tasks/main.yml' manca."
  ["playbook_no_role"]="Il 'playbook.yml' non usa il ruolo 'webserver'."
  ["install_task_missing"]="Il compito per installare Apache manca in 'roles/webserver/tasks/main.yml'."
  ["start_task_missing"]="Il compito per avviare il servizio Apache manca in 'roles/webserver/tasks/main.yml'."
  ["success"]="I compiti sono stati rifattorizzati con successo nel ruolo 'webserver'."
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

# Check if 'roles/webserver' directory exists
if [[ ! -d "roles/webserver" ]]; then
  echo "$(get_message role_dir_missing)"
  exit 1
fi

# Check if 'roles/webserver/tasks/main.yml' exists
if [[ ! -f "roles/webserver/tasks/main.yml" ]]; then
  echo "$(get_message tasks_file_missing)"
  exit 1
fi

# Check if 'playbook.yml' uses the 'webserver' role
if ! grep -q "roles:" "playbook.yml" || ! grep -q "webserver" "playbook.yml"; then
  echo "$(get_message playbook_no_role)"
  exit 1
fi

# Check if the install Apache task is in 'main.yml'
if ! grep -q "ansible.builtin.apt" "roles/webserver/tasks/main.yml" || ! grep -q "name: apache2" "roles/webserver/tasks/main.yml"; then
  echo "$(get_message install_task_missing)"
  exit 1
fi

# Check if the start Apache task is in 'main.yml'
if ! grep -q "ansible.builtin.service" "roles/webserver/tasks/main.yml" || ! grep -q "name: apache2" "roles/webserver/tasks/main.yml" || ! grep -q "state: started" "roles/webserver/tasks/main.yml"; then
  echo "$(get_message start_task_missing)"
  exit 1
fi

# If all checks pass
echo "{\"result\": \"0\"}"