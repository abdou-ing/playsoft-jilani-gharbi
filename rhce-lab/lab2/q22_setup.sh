#!/bin/bash

# Enable debugging if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="What is the configured Ansible inventory file?"
    hint="Use 'ansible-config dump' to check the current Ansible configuration."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to check the configured Ansible inventory file.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_HOST_LIST\"
                  }
                ]"
    ;;
  "fr")
    question="Quel est le fichier d'inventaire Ansible configuré ?"
    hint="Utilisez 'ansible-config dump' pour vérifier la configuration actuelle d'Ansible."
    instructions="[
                  {
                    \"instruction\": \"Exécutez la commande suivante pour vérifier le fichier d'inventaire Ansible configuré.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_HOST_LIST\"
                  }
                ]"
    ;;
  "es")
    question="¿Cuál es el archivo de inventario de Ansible configurado?"
    hint="Usa 'ansible-config dump' para verificar la configuración actual de Ansible."
    instructions="[
                  {
                    \"instruction\": \"Ejecuta el siguiente comando para verificar el archivo de inventario de Ansible configurado.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_HOST_LIST\"
                  }
                ]"
    ;;
  "it")
    question="Qual è il file di inventario di Ansible configurato?"
    hint="Usa 'ansible-config dump' per controllare la configurazione corrente di Ansible."
    instructions="[
                  {
                    \"instruction\": \"Esegui il seguente comando per verificare il file di inventario di Ansible configurato.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_HOST_LIST\"
                  }
                ]"
    ;;
  "de")
    question="Was ist die konfigurierte Ansible-Inventardatei?"
    hint="Verwenden Sie 'ansible-config dump', um die aktuelle Ansible-Konfiguration zu überprüfen."
    instructions="[
                  {
                    \"instruction\": \"Führen Sie den folgenden Befehl aus, um die konfigurierte Ansible-Inventardatei zu überprüfen.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_HOST_LIST\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the configured Ansible inventory file?"
    hint="Use 'ansible-config dump' to check the current Ansible configuration."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to check the configured Ansible inventory file.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_HOST_LIST\"
                  }
                ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  inventory_path="Ansible not installed"
  answer_a="/etc/ansible/hosts"
  answer_b="~/.ansible/inventory"
  answer_c="Ansible not installed"
  answer_d="/usr/local/etc/ansible/hosts"
  correct_answer="Ansible not installed"
else
  # Execute the command as ansible_user
  inventory_path=$(sudo -u ansible_user bash -c "ansible-config dump 2>/dev/null | grep 'DEFAULT_HOST_LIST' | awk '{print \$3}' | tr -d '[]'" || echo "No inventory file set")
  correct_answer="$inventory_path"

  # Generate distractor answers
  answer_a="~/hosts"
  answer_b="$inventory_path"
  answer_c="~/.ansible/inventory"
  answer_d="/usr/local/etc/ansible/hosts"
fi

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers to avoid predictable order
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the display JSON
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": {
    '"$shuffled_answers"'
  },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$correct_answer"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
