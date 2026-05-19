#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_install_project"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["ansible_not_installed"]="Ansible is not installed on the system."
  ["ansible_version_fail"]="Unable to verify Ansible version."
  ["success"]="Ansible is successfully installed and ready for use."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["ansible_not_installed"]="Ansible n'est pas installé sur le système."
  ["ansible_version_fail"]="Impossible de vérifier la version d'Ansible."
  ["success"]="Ansible est installé avec succès et prêt à l'emploi."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["ansible_not_installed"]="Ansible ist nicht auf dem System installiert."
  ["ansible_version_fail"]="Die Ansible-Version konnte nicht überprüft werden."
  ["success"]="Ansible ist erfolgreich installiert und einsatzbereit."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["ansible_not_installed"]="Ansible no está instalado en el sistema."
  ["ansible_version_fail"]="No se pudo verificar la versión de Ansible."
  ["success"]="Ansible está instalado correctamente y listo para usar."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["ansible_not_installed"]="Ansible non è installato sul sistema."
  ["ansible_version_fail"]="Impossibile verificare la versione di Ansible."
  ["success"]="Ansible è stato installato con successo ed è pronto per l'uso."
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

# Check if Ansible is installed (check if 'ansible' command is available)
if ! command -v ansible >/dev/null 2>&1; then
  echo "$(get_message ansible_not_installed)"
  exit 1
fi

# Check if Ansible version can be retrieved (ensures it's functional)
if ! ansible --version >/dev/null 2>&1; then
  echo "$(get_message ansible_version_fail)"
  exit 1
fi

# If all checks pass
echo "{\"result\": \"0\"}"