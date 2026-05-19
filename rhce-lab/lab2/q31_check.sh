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
playbook_name="create_config_playbook.yml"
config_file_path="/etc/my_config"

# Define translations for each language
declare -A messages_en=(
  ["playbook_not_found"]="Error: The playbook '$playbook_name' does not exist in '$code_path'."
  ["config_not_created"]="Error: The config file '$config_file_path' was not created."
  ["playbook_execution_failed"]="Error: Failed to execute the playbook as 'ansible_user'."
  ["error_captured"]="Error captured:"
  ["success"]="Success: The playbook exists and the config file was created."
)

declare -A messages_fr=(
  ["playbook_not_found"]="Erreur : Le playbook '$playbook_name' n'existe pas dans '$code_path'."
  ["config_not_created"]="Erreur : Le fichier de configuration '$config_file_path' n'a pas été créé."
  ["playbook_execution_failed"]="Erreur : Échec de l'exécution du playbook en tant que 'ansible_user'."
  ["error_captured"]="Erreur capturée :"
  ["success"]="Succès : Le playbook existe et le fichier de configuration a été créé."
)

declare -A messages_de=(
  ["playbook_not_found"]="Fehler: Das Playbook '$playbook_name' existiert nicht in '$code_path'."
  ["config_not_created"]="Fehler: Die Konfigurationsdatei '$config_file_path' wurde nicht erstellt."
  ["playbook_execution_failed"]="Fehler: Ausführung des Playbooks als 'ansible_user' fehlgeschlagen."
  ["error_captured"]="Fehler erfasst:"
  ["success"]="Erfolg: Das Playbook existiert und die Konfigurationsdatei wurde erstellt."
)

declare -A messages_es=(
  ["playbook_not_found"]="Error: El playbook '$playbook_name' no existe en '$code_path'."
  ["config_not_created"]="Error: El archivo de configuración '$config_file_path' no fue creado."
  ["playbook_execution_failed"]="Error: No se pudo ejecutar el playbook como 'ansible_user'."
  ["error_captured"]="Error capturado:"
  ["success"]="Éxito: El playbook existe y se creó el archivo de configuración."
)

declare -A messages_it=(
  ["playbook_not_found"]="Errore: Il playbook '$playbook_name' non esiste in '$code_path'."
  ["config_not_created"]="Errore: Il file di configurazione '$config_file_path' non è stato creato."
  ["playbook_execution_failed"]="Errore: Impossibile eseguire il playbook come 'ansible_user'."
  ["error_captured"]="Errore catturato:"
  ["success"]="Successo: Il playbook esiste e il file di configurazione è stato creato."
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

error_output=$(sudo -u ansible_user ansible-playbook "$code_path/$playbook_name" 2>&1 | grep "FAILED")
# Run the playbook as ansible_user and check for success
#if ! sudo -u ansible_user ansible-playbook "$code_path/$playbook_name" 2>&1 | grep "fatal:"; then
#  echo "$(get_message playbook_execution_failed)"
#  exit 1
#fi

# Check if there's an error and save it
if [[ -n "$error_output" ]]; then
    echo "$(get_message error_captured)"
    echo "$error_output"
    # Optionally save it to a file or variable for further processing
    #echo "$error_output" > playbook_error.log
    exit 1
fi

# Validate if the config file is created
if [[ ! -f "$config_file_path" ]]; then
  echo "$(get_message config_not_created)"
  exit 1
fi

# If all checks pass, output success
#echo "$(get_message success)"
echo "{\"result\": \"0\"}"
