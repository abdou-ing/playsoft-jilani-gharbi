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

# Define the code path
code_path="/home/ansible_user/ansible"
user_playbook_name="user_playbook.yml"

# Define translations for each language
declare -A messages_en=(
  ["user_not_found"]="Error: User 'john' does not exist. Ensure the playbook creates the user correctly."
  ["sudo_not_configured"]="Error: User 'john' does not have the correct sudo privileges. Ensure the playbook adds the appropriate configuration to '/etc/sudoers.d/john'."
  ["playbook_not_found"]="Error: The playbook '$user_playbook_name' does not exist in '$code_path'."
  ["all_checks_passed"]="Success: The playbook exists, user 'john' exists, and has correct sudo privileges."
  ["error_captured"]="Error captured:"
)

declare -A messages_fr=(
  ["user_not_found"]="Erreur : L'utilisateur 'john' n'existe pas. Assurez-vous que le playbook crée correctement l'utilisateur."
  ["sudo_not_configured"]="Erreur : L'utilisateur 'john' n'a pas les privilèges sudo corrects. Assurez-vous que le playbook ajoute la configuration appropriée dans '/etc/sudoers.d/john'."
  ["playbook_not_found"]="Erreur : Le playbook '$user_playbook_name' n'existe pas dans '$code_path'."
  ["all_checks_passed"]="Succès : Le playbook existe, l'utilisateur 'john' existe et dispose des privilèges sudo corrects."
  ["error_captured"]="Erreur capturée :"
)

declare -A messages_de=(
  ["user_not_found"]="Fehler: Der Benutzer 'john' existiert nicht. Stellen Sie sicher, dass das Playbook den Benutzer korrekt erstellt."
  ["sudo_not_configured"]="Fehler: Der Benutzer 'john' hat nicht die richtigen Sudo-Berechtigungen. Stellen Sie sicher, dass das Playbook die entsprechende Konfiguration in '/etc/sudoers.d/john' hinzufügt."
  ["playbook_not_found"]="Fehler: Das Playbook '$user_playbook_name' existiert nicht in '$code_path'."
  ["all_checks_passed"]="Erfolg: Das Playbook existiert, der Benutzer 'john' existiert und hat die richtigen Sudo-Berechtigungen."
  ["error_captured"]="Fehler erfasst:"
)

declare -A messages_es=(
  ["user_not_found"]="Error: El usuario 'john' no existe. Asegúrese de que el playbook crea el usuario correctamente."
  ["sudo_not_configured"]="Error: El usuario 'john' no tiene los privilegios de sudo correctos. Asegúrese de que el playbook agregue la configuración adecuada a '/etc/sudoers.d/john'."
  ["playbook_not_found"]="Error: El playbook '$user_playbook_name' no existe en '$code_path'."
  ["all_checks_passed"]="Éxito: El playbook existe, el usuario 'john' existe y tiene los privilegios de sudo correctos."
  ["error_captured"]="Error capturado:"
)

declare -A messages_it=(
  ["user_not_found"]="Errore: L'utente 'john' non esiste. Assicurati che il playbook crei correttamente l'utente."
  ["sudo_not_configured"]="Errore: L'utente 'john' non ha i privilegi sudo corretti. Assicurati che il playbook aggiunga la configurazione appropriata a '/etc/sudoers.d/john'."
  ["playbook_not_found"]="Errore: Il playbook '$user_playbook_name' non esiste in '$code_path'."
  ["all_checks_passed"]="Successo: Il playbook esiste, l'utente 'john' esiste e ha i privilegi sudo corretti."
  ["error_captured"]="Errore catturato:"
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

# Verify if the playbook exists in the specified directory
if [[ ! -f "$code_path/$user_playbook_name" ]]; then
  echo "$(get_message playbook_not_found)"
  exit 1
fi

error_output=$(sudo -u ansible_user ansible-playbook "$code_path/$user_playbook_name" 2>&1 | grep "FAILED")
# Check if there's an error and save it
if [[ -n "$error_output" ]]; then
    echo "$(get_message error_captured)"
    echo "$error_output"
    # Optionally save it to a file or variable for further processing
    #echo "$error_output" > playbook_error.log
    exit 1
fi

# Verify if the user 'john' exists
if ! id "john" &>/dev/null; then
  echo "$(get_message user_not_found)"
  exit 1
fi

# Verify if sudo privileges are correctly configured
if ! sudo -l -U john | grep -qE "NOPASSWD:\s*ALL"; then
  echo "$(get_message sudo_not_configured)"
  exit 1
fi

# If all checks pass, output success
#echo "$(get_message all_checks_passed)"
echo "{\"result\": \"0\"}"
