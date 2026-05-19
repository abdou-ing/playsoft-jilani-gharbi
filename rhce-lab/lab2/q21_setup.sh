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
    question="What is the installed version of Ansible?"
    hint="Use \`'ansible --help\` to see all available options."
    instructions="[
                  {
                    \"instruction\": \"Run 'ansible --version' to check the installed version of Ansible\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    ;;
  "fr")
    question="Quelle est la version installée d'Ansible ?"
    hint="Utilisez \`'ansible --help\` pour voir toutes les options disponibles."
    instructions="[
                  {
                    \"instruction\": \"Exécutez 'ansible --version' pour vérifier la version installée d'Ansible\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    ;;
  "de")
    question="Welche Version von Ansible ist installiert?"
    hint="Verwenden Sie \`'ansible --help\`, um alle verfügbaren Optionen anzuzeigen."
    instructions="[
                  {
                    \"instruction\": \"Führen Sie 'ansible --version' aus, um die installierte Version von Ansible zu überprüfen\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    ;;
  "es")
    question="¿Cuál es la versión instalada de Ansible?"
    hint="Usa \`'ansible --help\` para ver todas las opciones disponibles."
    instructions="[
                  {
                    \"instruction\": \"Ejecuta 'ansible --version' para verificar la versión instalada de Ansible\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    ;;
  "it")
    question="Qual è la versione installata di Ansible?"
    hint="Usa \`'ansible --help\` per vedere tutte le opzioni disponibili."
    instructions="[
                  {
                    \"instruction\": \"Esegui 'ansible --version' per verificare la versione installata di Ansible\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the installed version of Ansible?"
    hint="Use \`'ansible --help\` to see all available options."
    instructions="[
                  {
                    \"instruction\": \"Run 'ansible --version' to check the installed version of Ansible\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    ;;
esac

# Check if Ansible is installed
if ! command -v ansible &>/dev/null; then
  ansible_version="Not Installed"
  answer_a="2.0.3"
  answer_b="3.16.0"
  answer_c="2.15.4"
  answer_d="2.16.5"
  correct_answer="Not Installed"
else
  # Extract version from `ansible --version`
  ansible_version=$(ansible --version | grep -oP '(?<=\[core )\d+\.\d+\.\d+(?=\])')
  correct_answer="$ansible_version"

  # Generate distractor answers
  answer_a=$(echo "$ansible_version" | awk -F'.' '{print $1+1".0."$3}')
  answer_b="$ansible_version"
  answer_c=$(echo "$ansible_version" | awk -F'.' '{print $1"."$2-1"."$3+1}')
  answer_d=$(echo "$ansible_version" | awk -F'.' '{print $1+2"."$2"."$3+5}')
fi

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the display JSON
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": {
    '"$shuffled_answers"'
  },
  "solution": "'"$correct_answer"'",
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Use jq to pretty print the JSON (optional)
echo "$display" | jq .