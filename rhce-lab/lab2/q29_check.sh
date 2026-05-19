#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

# List of supported languages
supported_languages=("en" "fr" "de" "es" "it")

# Check if the provided language is supported
if [[ ! " ${supported_languages[@]} " =~ " $lang " ]]; then
  lang="en"  # Default to English if the language is not supported
fi

# Define the code path and playbook name
code_path="/home/ansible_user/ansible"
playbook_name="nginx_playbook.yml"

# Define translations for each language
declare -A messages_en=(
  ["playbook_not_found"]="Error: The playbook '$playbook_name' does not exist in '$code_path'."
  ["nginx_not_installed"]="Error: nginx is not installed."
  ["nginx_not_running"]="Error: nginx is not running."
  ["success"]="Success: The playbook exists, nginx is installed, and nginx is running."
)

declare -A messages_fr=(
  ["playbook_not_found"]="Erreur : Le playbook '$playbook_name' n'existe pas dans '$code_path'."
  ["nginx_not_installed"]="Erreur : nginx n'est pas installé."
  ["nginx_not_running"]="Erreur : nginx n'est pas en cours d'exécution."
  ["success"]="Succès : Le playbook existe, nginx est installé et nginx est en cours d'exécution."
)

declare -A messages_de=(
  ["playbook_not_found"]="Fehler: Das Playbook '$playbook_name' existiert nicht in '$code_path'."
  ["nginx_not_installed"]="Fehler: nginx ist nicht installiert."
  ["nginx_not_running"]="Fehler: nginx läuft nicht."
  ["success"]="Erfolg: Das Playbook existiert, nginx ist installiert und nginx läuft."
)

declare -A messages_es=(
  ["playbook_not_found"]="Error: El playbook '$playbook_name' no existe en '$code_path'."
  ["nginx_not_installed"]="Error: nginx no está instalado."
  ["nginx_not_running"]="Error: nginx no está en ejecución."
  ["success"]="Éxito: El playbook existe, nginx está instalado y nginx está en ejecución."
)

declare -A messages_it=(
  ["playbook_not_found"]="Errore: Il playbook '$playbook_name' non esiste in '$code_path'."
  ["nginx_not_installed"]="Errore: nginx non è installato."
  ["nginx_not_running"]="Errore: nginx non è in esecuzione."
  ["success"]="Successo: Il playbook esiste, nginx è installato e nginx è in esecuzione."
)

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

# Check if the playbook exists in the specified directory
if [[ ! -f "$code_path/$playbook_name" ]]; then
  echo "$(get_message playbook_not_found)"
  exit 1
fi

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
  echo "$(get_message nginx_not_installed)"
  exit 1
fi

# Check if nginx is running using the 'service' command
if ! service nginx status &> /dev/null; then
  echo "$(get_message nginx_not_running)"
  exit 1
fi

# If all checks pass, output success
#echo "$(get_message success)"
echo "{\"result\": \"0\"}"