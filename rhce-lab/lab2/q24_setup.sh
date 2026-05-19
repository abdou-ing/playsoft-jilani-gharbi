#!/bin/bash

# Check if "debug" is passed as an argument
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
    question="What is the configured log path for Ansible?"
    hint="Use 'ansible-config dump' to check the current Ansible configuration."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to check the configured Ansible log path.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_LOG_PATH\"
                  }
                ]"
    ;;
  "fr")
    question="Quel est le chemin du fichier de logs configuré pour Ansible ?"
    hint="Utilisez 'ansible-config dump' pour vérifier la configuration actuelle d'Ansible."
    instructions="[
                  {
                    \"instruction\": \"Exécutez la commande suivante pour vérifier le chemin du fichier de logs configuré pour Ansible.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_LOG_PATH\"
                  }
                ]"
    ;;
  "es")
    question="¿Cuál es la ruta configurada para los logs de Ansible?"
    hint="Usa 'ansible-config dump' para verificar la configuración actual de Ansible."
    instructions="[
                  {
                    \"instruction\": \"Ejecuta el siguiente comando para verificar la ruta configurada para los logs de Ansible.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_LOG_PATH\"
                  }
                ]"
    ;;
  "it")
    question="Qual è il percorso configurato per i log di Ansible?"
    hint="Usa 'ansible-config dump' per controllare la configurazione corrente di Ansible."
    instructions="[
                  {
                    \"instruction\": \"Esegui il seguente comando per verificare il percorso configurato per i log di Ansible.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_LOG_PATH\"
                  }
                ]"
    ;;
  "de")
    question="Was ist der konfigurierte Log-Pfad für Ansible?"
    hint="Verwenden Sie 'ansible-config dump', um die aktuelle Ansible-Konfiguration zu überprüfen."
    instructions="[
                  {
                    \"instruction\": \"Führen Sie den folgenden Befehl aus, um den konfigurierten Log-Pfad für Ansible zu überprüfen.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_LOG_PATH\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the configured log path for Ansible?"
    hint="Use 'ansible-config dump' to check the current Ansible configuration."
    instructions="[
                  {
                    \"instruction\": \"Run the following command to check the configured Ansible log path.\",
                    \"command\": \"ansible-config dump | grep DEFAULT_LOG_PATH\"
                  }
                ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  log_path="Ansible not installed"
  answer_a="/var/log/ansible.log"
  answer_b="~/ansible/logs/ansible.log"
  answer_c="Ansible not installed"
  answer_d="/tmp/ansible-debug.log"
  correct_answer="Ansible not installed"
else
  # Execute the log_path command as ansible_user
  log_path=$(sudo -u ansible_user bash -c "ansible-config dump 2>/dev/null | grep 'DEFAULT_LOG_PATH' | awk '{print \$3}' | tr -d '[]'" || echo "No log path set")

  correct_answer="$log_path"

  # Generate distractor answers
  answer_a="/var/log/ansible.log"
  answer_b="$log_path"
  answer_c="~/ansible/logs/ansible.log"
  answer_d="/tmp/ansible-debug.log"
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