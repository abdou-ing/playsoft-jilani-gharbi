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
    question="What is the configured collection path for Ansible?"
    hint="Use <span class=\\\"bold-green-text\\\">ansible-config dump</span> to check the current Ansible configuration."
    instructions="[
      {
        \"instruction\": \"Run the command <span class=\\\"bold-green-text\\\">ansible-config dump</span> to view all Ansible configuration settings.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filter the output to find the collection path.\",
        \"command\": \"ansible-config dump | grep COLLECTIONS_PATHS\"
      }
    ]"
    ;;
  "fr")
    question="Quel est le chemin de collection configuré pour Ansible ?"
    hint="Utilisez <span class=\\\"bold-green-text\\\">ansible-config dump</span> pour vérifier la configuration actuelle d'Ansible."
    instructions="[
      {
        \"instruction\": \"Exécutez la commande <span class=\\\"bold-green-text\\\">ansible-config dump</span> pour afficher tous les paramètres de configuration d'Ansible.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtrez la sortie pour trouver le chemin de collection.\",
        \"command\": \"ansible-config dump | grep COLLECTIONS_PATHS\"
      }
    ]"
    ;;
  "es")
    question="¿Cuál es la ruta de colección configurada para Ansible?"
    hint="Utiliza <span class=\\\"bold-green-text\\\">ansible-config dump</span> para comprobar la configuración actual de Ansible."
    instructions="[
      {
        \"instruction\": \"Ejecuta el comando <span class=\\\"bold-green-text\\\">ansible-config dump</span> para ver todas las configuraciones de Ansible.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtra la salida para encontrar la ruta de colección.\",
        \"command\": \"ansible-config dump | grep COLLECTIONS_PATHS\"
      }
    ]"
    ;;
  "it")
    question="Qual è il percorso di raccolta configurato per Ansible?"
    hint="Usa <span class=\\\"bold-green-text\\\">ansible-config dump</span> per controllare la configurazione attuale di Ansible."
    instructions="[
      {
        \"instruction\": \"Esegui il comando <span class=\\\"bold-green-text\\\">ansible-config dump</span> per visualizzare tutte le impostazioni di configurazione di Ansible.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtra l'output per trovare il percorso della raccolta.\",
        \"command\": \"ansible-config dump | grep COLLECTIONS_PATHS\"
      }
    ]"
    ;;
  "de")
    question="Welcher Sammlungsweg ist für Ansible konfiguriert?"
    hint="Verwenden Sie <span class=\\\"bold-green-text\\\">ansible-config dump</span>, um die aktuelle Ansible-Konfiguration zu überprüfen."
    instructions="[
      {
        \"instruction\": \"Führen Sie den Befehl <span class=\\\"bold-green-text\\\">ansible-config dump</span> aus, um alle Ansible-Konfigurationseinstellungen anzuzeigen.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filtern Sie die Ausgabe, um den Sammlungsweg zu finden.\",
        \"command\": \"ansible-config dump | grep COLLECTIONS_PATHS\"
      }
    ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the configured collection path for Ansible?"
    hint="Use <span class=\\\"bold-green-text\\\">ansible-config dump</span> to check the current Ansible configuration."
    instructions="[
      {
        \"instruction\": \"Run the command <span class=\\\"bold-green-text\\\">ansible-config dump</span> to view all Ansible configuration settings.\",
        \"command\": \"ansible-config dump\"
      },
      {
        \"instruction\": \"Filter the output to find the collection path.\",
        \"command\": \"ansible-config dump | grep COLLECTIONS_PATHS\"
      }
    ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  collection_path="Ansible not installed"
  answer_a="/usr/share/ansible/collections"
  answer_b="~/.ansible/collections"
  answer_c="Ansible not installed"
  answer_d="/etc/ansible/collections"
  correct_answer="Ansible not installed"
else
  # Fetch the collection path from the Ansible configuration
  collection_path=$(sudo su - ansible_user -c "ansible-config dump 2>/dev/null | grep "COLLECTIONS_PATHS" | awk -F'[][]' '{print $2}' | tr -d '[]' || echo "No collection path set"")
  correct_answer="$collection_path"

  # Generate distractor answers
  answer_a="/usr/share/ansible/collections"
  answer_b="$collection_path"
  answer_c="~/.ansible/collections"
  answer_d="/etc/ansible/collections"
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
