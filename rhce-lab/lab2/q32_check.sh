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

# Define the code path and playbook names
code_path="/home/ansible_user/ansible"
apache_playbook="apache_playbook.yml"
apache_service="apache2"
remote_host="web1"

# Define translations for each language
declare -A messages_en=(
  ["apache_playbook_not_found"]="Error: The playbook '$apache_playbook' does not exist in '$code_path'."
  ["apache_not_installed_or_running"]="Error: The '$apache_service' service is not installed or not running on '$remote_host'."
  ["error_captured"]="Error captured:"
  ["success_apache"]="Success: The apache playbook exists, '$apache_service' is installed and running on '$remote_host'."
)

declare -A messages_fr=(
  ["apache_playbook_not_found"]="Erreur : Le playbook '$apache_playbook' n'existe pas dans '$code_path'."
  ["apache_not_installed_or_running"]="Erreur : Le service '$apache_service' n'est pas installé ou ne fonctionne pas sur '$remote_host'."
  ["error_captured"]="Erreur capturée :"
  ["success_apache"]="Succès : Le playbook apache existe, '$apache_service' est installé et fonctionne sur '$remote_host'."
)

declare -A messages_de=(
  ["apache_playbook_not_found"]="Fehler: Das Playbook '$apache_playbook' existiert nicht in '$code_path'."
  ["apache_not_installed_or_running"]="Fehler: Der Dienst '$apache_service' ist auf '$remote_host' nicht installiert oder läuft nicht."
  ["error_captured"]="Fehler erfasst:"
  ["success_apache"]="Erfolg: Das Apache-Playbook existiert, '$apache_service' ist installiert und läuft auf '$remote_host'."
)

declare -A messages_es=(
  ["apache_playbook_not_found"]="Error: El playbook '$apache_playbook' no existe en '$code_path'."
  ["apache_not_installed_or_running"]="Error: El servicio '$apache_service' no está instalado o en ejecución en '$remote_host'."
  ["error_captured"]="Error capturado:"
  ["success_apache"]="Éxito: El playbook apache existe, '$apache_service' está instalado y en ejecución en '$remote_host'."
)

declare -A messages_it=(
  ["apache_playbook_not_found"]="Errore: Il playbook '$apache_playbook' non esiste in '$code_path'."
  ["apache_not_installed_or_running"]="Errore: Il servizio '$apache_service' non è installato o non è in esecuzione su '$remote_host'."
  ["error_captured"]="Errore catturato:"
  ["success_apache"]="Successo: Il playbook apache esiste, '$apache_service' è installato e in esecuzione su '$remote_host'."
)

# Add translations for other languages as needed...

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


# Check for and validate the apache_playbook.yml
if [[ ! -f "$code_path/$apache_playbook" ]]; then
  echo "$(get_message apache_playbook_not_found)"
  exit 1
fi

error_output=$(sudo -u ansible_user ansible-playbook "$code_path/$apache_playbook" 2>&1 | grep "FAILED")

# Check if there's an error and save it
if [[ -n "$error_output" ]]; then
    echo "$(get_message error_captured)"
    echo "$error_output"
    # Optionally save it to a file or variable for further processing
    #echo "$error_output" > playbook_error.log
    exit 1
fi


# Validate apache service is installed and running on web1
if ! sudo -u ansible_user ansible -m shell -a "service $apache_service status" "$remote_host" | grep -q "running"; then
  echo "$(get_message apache_not_installed_or_running)"
  exit 1
fi

# If all checks pass, output success
#echo "$(get_message success_apache)"
echo "{\"result\": \"0\"}"
