#!/bin/bash
# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="What language are Ansible playbooks, roles, and collections primarily written in?"
    hint="Think about the format used to define tasks and configurations in Ansible ..."
    instructions="[
                  {
                    \"instruction\": \"Consider the syntax used for Ansible’s configuration files and how tasks are structured. The correct answer is: Ansible playbooks, roles, and collections are primarily written in YAML.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible playbooks, roles, and collections are primarily written in Python."
    answer_b="Ansible playbooks, roles, and collections are primarily written in YAML."  # Correct answer
    answer_c="Ansible playbooks, roles, and collections are primarily written in JSON."
    answer_d="Ansible playbooks, roles, and collections are primarily written in Bash."
    ;;
  "fr")
    question="Dans quel langage les playbooks, rôles et collections d'Ansible sont-ils principalement écrits ?"
    hint="Pensez au format utilisé pour définir les tâches et les configurations dans Ansible ..."
    instructions="[
                  {
                    \"instruction\": \"Considérez la syntaxe utilisée pour les fichiers de configuration d'Ansible et la manière dont les tâches sont structurées. La réponse correcte est : Les playbooks, rôles et collections d'Ansible sont principalement écrits en YAML.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Les playbooks, rôles et collections d'Ansible sont principalement écrits en Python."
    answer_b="Les playbooks, rôles et collections d'Ansible sont principalement écrits en YAML."  # Réponse correcte
    answer_c="Les playbooks, rôles et collections d'Ansible sont principalement écrits en JSON."
    answer_d="Les playbooks, rôles et collections d'Ansible sont principalement écrits en Bash."
    ;;
  "de")
    question="In welcher Sprache sind Ansible-Playbooks, Rollen und Sammlungen hauptsächlich geschrieben?"
    hint="Überlegen Sie, welches Format verwendet wird, um Aufgaben und Konfigurationen in Ansible zu definieren ..."
    instructions="[
                  {
                    \"instruction\": \"Betrachten Sie die Syntax, die für Ansible-Konfigurationsdateien verwendet wird, und wie Aufgaben strukturiert sind. Die richtige Antwort lautet: Ansible-Playbooks, Rollen und Sammlungen sind hauptsächlich in YAML geschrieben.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible-Playbooks, Rollen und Sammlungen sind hauptsächlich in Python geschrieben."
    answer_b="Ansible-Playbooks, Rollen und Sammlungen sind hauptsächlich in YAML geschrieben."  # Richtige Antwort
    answer_c="Ansible-Playbooks, Rollen und Sammlungen sind hauptsächlich in JSON geschrieben."
    answer_d="Ansible-Playbooks, Rollen und Sammlungen sind hauptsächlich in Bash geschrieben."
    ;;
  "it")
    question="In quale linguaggio sono scritti principalmente i playbook, i ruoli e le collezioni di Ansible?"
    hint="Pensa al formato utilizzato per definire compiti e configurazioni in Ansible ..."
    instructions="[
                  {
                    \"instruction\": \"Considera la sintassi usata per i file di configurazione di Ansible e come sono strutturati i compiti. La risposta corretta è: I playbook, i ruoli e le collezioni di Ansible sono principalmente scritti in YAML.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="I playbook, i ruoli e le collezioni di Ansible sono principalmente scritti in Python."
    answer_b="I playbook, i ruoli e le collezioni di Ansible sono principalmente scritti in YAML."  # Risposta corretta
    answer_c="I playbook, i ruoli e le collezioni di Ansible sono principalmente scritti in JSON."
    answer_d="I playbook, i ruoli e le collezioni di Ansible sono principalmente scritti in Bash."
    ;;
  "es")
    question="¿En qué lenguaje están escritos principalmente los playbooks, roles y colecciones de Ansible?"
    hint="Piensa en el formato utilizado para definir tareas y configuraciones en Ansible ..."
    instructions="[
                  {
                    \"instruction\": \"Considera la sintaxis utilizada para los archivos de configuración de Ansible y cómo se estructuran las tareas. La respuesta correcta es: Los playbooks, roles y colecciones de Ansible están principalmente escritos en YAML.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Los playbooks, roles y colecciones de Ansible están principalmente escritos en Python."
    answer_b="Los playbooks, roles y colecciones de Ansible están principalmente escritos en YAML."  # Respuesta correcta
    answer_c="Los playbooks, roles y colecciones de Ansible están principalmente escritos en JSON."
    answer_d="Los playbooks, roles y colecciones de Ansible están principalmente escritos en Bash."
    ;;
  *)
    # Default to English if the language is not supported
    question="What language are Ansible playbooks, roles, and collections primarily written in?"
    hint="Think about the format used to define tasks and configurations in Ansible ..."
    instructions="[
                  {
                    \"instruction\": \"Consider the syntax used for Ansible’s configuration files and how tasks are structured. The correct answer is: Ansible playbooks, roles, and collections are primarily written in YAML.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible playbooks, roles, and collections are primarily written in Python."
    answer_b="Ansible playbooks, roles, and collections are primarily written in YAML."  # Correct answer
    answer_c="Ansible playbooks, roles, and collections are primarily written in JSON."
    answer_d="Ansible playbooks, roles, and collections are primarily written in Bash."
    ;;
esac

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers and format them as a valid JSON object
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the display JSON
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": { '"$shuffled_answers"' },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$answer_b"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Use jq to pretty print the JSON (optional)
echo "$display" | jq .