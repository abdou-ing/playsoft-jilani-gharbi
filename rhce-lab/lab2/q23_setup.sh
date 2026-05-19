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
    question="What is the configured default path for Ansible roles?"
    hint="Use 'ansible-config dump' to check the current Ansible configuration."
    instructions="[
      {
        \"instruction\": \"Run the command 'ansible-config dump' to view all Ansible configuration settings.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filter the output to find the default roles path.\",
        \"command\": \"ansible-config dump | grep DEFAULT_ROLES_PATH\"
      }
    ]"
    ;;
  "fr")
    question="Quel est le chemin par défaut configuré pour les rôles Ansible ?"
    hint="Utilisez 'ansible-config dump' pour vérifier la configuration actuelle d'Ansible."
    instructions="[
      {
        \"instruction\": \"Exécutez la commande 'ansible-config dump' pour afficher tous les paramètres de configuration d'Ansible.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtrez la sortie pour trouver le chemin des rôles par défaut.\",
        \"command\": \"ansible-config dump | grep DEFAULT_ROLES_PATH\"
      }
    ]"
    ;;
  "es")
    question="¿Cuál es la ruta predeterminada configurada para los roles de Ansible?"
    hint="Utiliza 'ansible-config dump' para comprobar la configuración actual de Ansible."
    instructions="[
      {
        \"instruction\": \"Ejecuta el comando 'ansible-config dump' para ver todas las configuraciones de Ansible.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtra la salida para encontrar la ruta predeterminada de los roles.\",
        \"command\": \"ansible-config dump | grep DEFAULT_ROLES_PATH\"
      }
    ]"
    ;;
  "it")
    question="Qual è il percorso predefinito configurato per i ruoli Ansible?"
    hint="Usa 'ansible-config dump' per controllare la configurazione attuale di Ansible."
    instructions="[
      {
        \"instruction\": \"Esegui il comando 'ansible-config dump' per visualizzare tutte le impostazioni di configurazione di Ansible.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtra l'output per trovare il percorso predefinito dei ruoli.\",
        \"command\": \"ansible-config dump | grep DEFAULT_ROLES_PATH\"
      }
    ]"
    ;;
  "de")
    question="Welcher Standardpfad ist für Ansible-Rollen konfiguriert?"
    hint="Verwenden Sie 'ansible-config dump', um die aktuelle Ansible-Konfiguration zu überprüfen."
    instructions="[
      {
        \"instruction\": \"Führen Sie den Befehl 'ansible-config dump' aus, um alle Ansible-Konfigurationseinstellungen anzuzeigen.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtern Sie die Ausgabe, um den Standardpfad für Rollen zu finden.\",
        \"command\": \"ansible-config dump | grep DEFAULT_ROLES_PATH\"
      }
    ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the configured default path for Ansible roles?"
    hint="Use 'ansible-config dump' to check the current Ansible configuration."
    instructions="[
      {
        \"instruction\": \"Run the command 'ansible-config dump' to view all Ansible configuration settings.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filter the output to find the default roles path.\",
        \"command\": \"ansible-config dump | grep DEFAULT_ROLES_PATH\"
      }
    ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  roles_path="Ansible not installed"
  answer_a="/etc/ansible/roles"
  answer_b="~/.ansible/roles"
  answer_c="Ansible not installed"
  answer_d="/usr/local/etc/ansible/roles"
  correct_answer="Ansible not installed"
else
  # Execute the roles_path command as ansible_user
  roles_path=$(sudo -u ansible_user bash -c "ansible-config dump 2>/dev/null | grep 'DEFAULT_ROLES_PATH' | awk -F'[][]' '{print \$2}'" || echo "No roles path set")

  correct_answer="$roles_path"

  # Generate distractor answers
  answer_a="/etc/ansible/roles"
  answer_b="$roles_path"
  answer_c="~/.ansible/roles"
  answer_d="/usr/local/etc/ansible/roles"
fi

# Create an array of answers
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")
# Shuffle the answers
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Construct the JSON display
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": { '"$shuffled_answers"' },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$correct_answer"'",
  "platform_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
