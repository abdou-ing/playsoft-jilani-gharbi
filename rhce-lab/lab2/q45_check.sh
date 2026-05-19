#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Set language argument, defaulting to "en" if none is provided
lang="${1:-en}"

project_dir="/home/ansible_user/ansible_default_inventory_project"
inventory_file="/etc/ansible/hosts"

# Define translations for each language
declare -A messages_en=(
  ["dir_not_found"]="The directory $project_dir does not exist."
  ["playbook_missing"]="The 'playbook.yml' file is missing."
  ["inventory_missing"]="The default inventory file $inventory_file is missing or inaccessible."
  ["dbservers_group_missing"]="The 'dbservers' group is not defined in $inventory_file."
  ["db1_missing"]="The host 'db1' is not listed under 'dbservers' in $inventory_file."
  ["db2_missing"]="The host 'db2' is not listed under 'dbservers' in $inventory_file."
  ["wrong_hosts"]="The playbook does not target the 'dbservers' group."
  ["become_missing"]="The 'become' directive is missing in 'playbook.yml'."
  ["apt_task_missing"]="The 'ansible.builtin.apt' task to install 'postgresql' is missing in 'playbook.yml'."
  ["apt_wrong_package"]="The 'ansible.builtin.apt' task does not specify 'postgresql' as the package."
  ["success"]="The 'dbservers' group with 'db1' and 'db2' is correctly appended to $inventory_file, and the playbook is configured to install 'postgresql' on 'dbservers'."
)

declare -A messages_fr=(
  ["dir_not_found"]="Le répertoire $project_dir n'existe pas."
  ["playbook_missing"]="Le fichier 'playbook.yml' est manquant."
  ["inventory_missing"]="Le fichier d'inventaire par défaut $inventory_file est manquant ou inaccessible."
  ["dbservers_group_missing"]="Le groupe 'dbservers' n'est pas défini dans $inventory_file."
  ["db1_missing"]="L'hôte 'db1' n'est pas listé sous 'dbservers' dans $inventory_file."
  ["db2_missing"]="L'hôte 'db2' n'est pas listé sous 'dbservers' dans $inventory_file."
  ["wrong_hosts"]="Le playbook ne cible pas le groupe 'dbservers'."
  ["become_missing"]="La directive 'become' est absente dans 'playbook.yml'."
  ["apt_task_missing"]="La tâche 'ansible.builtin.apt' pour installer 'postgresql' est absente dans 'playbook.yml'."
  ["apt_wrong_package"]="La tâche 'ansible.builtin.apt' ne spécifie pas 'postgresql' comme paquet."
  ["success"]="Le groupe 'dbservers' avec 'db1' et 'db2' est correctement ajouté à $inventory_file, et le playbook est configuré pour installer 'postgresql' sur 'dbservers'."
)

declare -A messages_de=(
  ["dir_not_found"]="Das Verzeichnis $project_dir existiert nicht."
  ["playbook_missing"]="Die Datei 'playbook.yml' fehlt."
  ["inventory_missing"]="Die Standard-Inventardatei $inventory_file fehlt oder ist nicht zugänglich."
  ["dbservers_group_missing"]="Die Gruppe 'dbservers' ist nicht in $inventory_file definiert."
  ["db1_missing"]="Der Host 'db1' ist nicht unter 'dbservers' in $inventory_file aufgeführt."
  ["db2_missing"]="Der Host 'db2' ist nicht unter 'dbservers' in $inventory_file aufgeführt."
  ["wrong_hosts"]="Das Playbook zielt nicht auf die Gruppe 'dbservers' ab."
  ["become_missing"]="Die Direktive 'become' fehlt in 'playbook.yml'."
  ["apt_task_missing"]="Die Aufgabe 'ansible.builtin.apt' zum Installieren von 'postgresql' fehlt in 'playbook.yml'."
  ["apt_wrong_package"]="Die Aufgabe 'ansible.builtin.apt' gibt 'postgresql' nicht als Paket an."
  ["success"]="Die Gruppe 'dbservers' mit 'db1' und 'db2' ist korrekt an $inventory_file angehängt, und das Playbook ist konfiguriert, um 'postgresql' auf 'dbservers' zu installieren."
)

declare -A messages_es=(
  ["dir_not_found"]="El directorio $project_dir no existe."
  ["playbook_missing"]="El archivo 'playbook.yml' no está presente."
  ["inventory_missing"]="El archivo de inventario por defecto $inventory_file no está presente o es inaccesible."
  ["dbservers_group_missing"]="El grupo 'dbservers' no está definido en $inventory_file."
  ["db1_missing"]="El host 'db1' no está listado bajo 'dbservers' en $inventory_file."
  ["db2_missing"]="El host 'db2' no está listado bajo 'dbservers' en $inventory_file."
  ["wrong_hosts"]="El playbook no apunta al grupo 'dbservers'."
  ["become_missing"]="La directiva 'become' no está en 'playbook.yml'."
  ["apt_task_missing"]="La tarea 'ansible.builtin.apt' para instalar 'postgresql' no está en 'playbook.yml'."
  ["apt_wrong_package"]="La tarea 'ansible.builtin.apt' no especifica 'postgresql' como paquete."
  ["success"]="El grupo 'dbservers' con 'db1' y 'db2' está correctamente añadido a $inventory_file, y el playbook está configurado para instalar 'postgresql' en 'dbservers'."
)

declare -A messages_it=(
  ["dir_not_found"]="La directory $project_dir non esiste."
  ["playbook_missing"]="Il file 'playbook.yml' manca."
  ["inventory_missing"]="Il file di inventario predefinito $inventory_file non è presente o non è accessibile."
  ["dbservers_group_missing"]="Il gruppo 'dbservers' non è definito in $inventory_file."
  ["db1_missing"]="L'host 'db1' non è elencato sotto 'dbservers' in $inventory_file."
  ["db2_missing"]="L'host 'db2' non è elencato sotto 'dbservers' in $inventory_file."
  ["wrong_hosts"]="Il playbook non punta al gruppo 'dbservers'."
  ["become_missing"]="La direttiva 'become' non è presente in 'playbook.yml'."
  ["apt_task_missing"]="Il compito 'ansible.builtin.apt' per installare 'postgresql' non è presente in 'playbook.yml'."
  ["apt_wrong_package"]="Il compito 'ansible.builtin.apt' non specifica 'postgresql' come pacchetto."
  ["success"]="Il gruppo 'dbservers' con 'db1' e 'db2' è correttamente aggiunto a $inventory_file, e il playbook è configurato per installare 'postgresql' su 'dbservers'."
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

## Check if 'playbook.yml' exists
#if [[ ! -f "playbook.yml" ]]; then
#  echo "$(get_message playbook_missing)"
#  exit 1
#fi

# Check if the default inventory file exists and is readable
if [[ ! -r "$inventory_file" ]]; then
  echo "$(get_message inventory_missing)"
  exit 1
fi

# Check if 'dbservers' group is defined in the inventory file
if ! grep -q "\[dbservers\]" "$inventory_file"; then
  echo "$(get_message dbservers_group_missing)"
  exit 1
fi

# Check if 'db1' is listed under 'dbservers'
if ! grep -A 2 "\[dbservers\]" "$inventory_file" | grep -q "db1"; then
  echo "$(get_message db1_missing)"
  exit 1
fi

# Check if 'db2' is listed under 'dbservers'
if ! grep -A 2 "\[dbservers\]" "$inventory_file" | grep -q "db2"; then
  echo "$(get_message db2_missing)"
  exit 1
fi

## Check if the playbook targets the 'dbservers' group
#if ! grep -q "hosts: dbservers" "playbook.yml"; then
#  echo "$(get_message wrong_hosts)"
#  exit 1
#fi
#
## Check if 'become' directive is present
#if ! grep -q "become: yes" "playbook.yml"; then
#  echo "$(get_message become_missing)"
#  exit 1
#fi

# Check if 'ansible.builtin.apt' task exists and targets 'postgresql'
#check_task_for_parameter "ansible.builtin.apt:" "name: postgresql" "apt_task_missing"

# If all checks pass
echo "{\"result\": \"0\"}"