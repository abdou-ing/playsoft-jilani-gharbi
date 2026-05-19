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

# Define variables
inventory_file="/etc/ansible/hosts"
remote_host="web1"

# Define translations for each language
declare -A messages_en=(
  ["inventory_file_not_found"]="Error: The inventory file '$inventory_file' does not exist."
  ["host_not_configured"]="Error: The remote host '$remote_host' is not configured in '$inventory_file'."
  ["not_able_to_ping"]="Error: Unable to ping the remote host '$remote_host' using Ansible."
  ["success_inventory"]="Success: The inventory file exists, '$remote_host' is configured correctly, and is reachable."
)

declare -A messages_fr=(
  ["inventory_file_not_found"]="Erreur : Le fichier d'inventaire '$inventory_file' n'existe pas."
  ["host_not_configured"]="Erreur : L'hôte distant '$remote_host' n'est pas configuré dans '$inventory_file'."
  ["not_able_to_ping"]="Erreur : Impossible de pinguer l'hôte distant '$remote_host' avec Ansible."
  ["success_inventory"]="Succès : Le fichier d'inventaire existe, '$remote_host' est configuré correctement et est joignable."
)

declare -A messages_de=(
  ["inventory_file_not_found"]="Fehler: Die Inventardatei '$inventory_file' existiert nicht."
  ["host_not_configured"]="Fehler: Der Remote-Host '$remote_host' ist nicht in '$inventory_file' konfiguriert."
  ["not_able_to_ping"]="Fehler: Der Remote-Host '$remote_host' kann mit Ansible nicht gepingt werden."
  ["success_inventory"]="Erfolg: Die Inventardatei existiert, '$remote_host' ist korrekt konfiguriert und erreichbar."
)

declare -A messages_es=(
  ["inventory_file_not_found"]="Error: El archivo de inventario '$inventory_file' no existe."
  ["host_not_configured"]="Error: El host remoto '$remote_host' no está configurado en '$inventory_file'."
  ["not_able_to_ping"]="Error: No se puede hacer ping al host remoto '$remote_host' con Ansible."
  ["success_inventory"]="Éxito: El archivo de inventario existe, '$remote_host' está configurado correctamente y es alcanzable."
)

declare -A messages_it=(
  ["inventory_file_not_found"]="Errore: Il file di inventario '$inventory_file' non esiste."
  ["host_not_configured"]="Errore: L'host remoto '$remote_host' non è configurato in '$inventory_file'."
  ["not_able_to_ping"]="Errore: Impossibile eseguire il ping dell'host remoto '$remote_host' con Ansible."
  ["success_inventory"]="Successo: Il file di inventario esiste, '$remote_host' è configurato correttamente ed è raggiungibile."
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

# Check if the inventory file exists
if [[ ! -f "$inventory_file" ]]; then
  echo "$(get_message inventory_file_not_found)"
  exit 1
fi

# Check if the remote host is configured in the inventory file
if ! grep -q "$remote_host" "$inventory_file"; then
  echo "$(get_message host_not_configured)"
  exit 1
fi

# Validate apache service is installed and running on web1
if ! sudo -u ansible_user ansible -i $inventory_file $remote_host -m ping | grep -q "pong"; then
  echo "$(get_message not_able_to_ping)"
  exit 1
fi

# If all checks pass, output success
echo "$(get_message success_inventory)"
