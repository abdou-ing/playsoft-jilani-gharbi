#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="Which play header parameter disables automatic fact gathering for a play?"
    hint="By default every play runs a hidden fact-gathering task first. A single parameter in the play header turns this off — useful when speed matters and facts are not needed."
    instructions="[
                  {
                    \"instruction\": \"Add <span class=\\\"bold-green-text\\\">gather_facts: no</span> to the play header to skip the implicit setup task.\",
                    \"command\": \"- name: play without facts\\n  hosts: all\\n  gather_facts: no\\n  tasks:\\n    - name: quick task\\n      command: uptime\"
                  },
                  {
                    \"instruction\": \"If facts are needed later in the same playbook, run the <span class=\\\"bold-green-text\\\">setup</span> module explicitly.\",
                    \"command\": \"- name: manually gather facts when needed\\n  setup:\"
                  }
                ]"
    answer_a="facts: disabled"
    answer_b="collect_facts: false"
    answer_c="gather_facts: no"  # Correct answer
    answer_d="setup: skip"
    ;;
  "fr")
    question="Quel paramètre d'en-tête de play désactive la collecte automatique des faits ?"
    hint="Par défaut, chaque play exécute d'abord une tâche cachée de collecte des faits. Un seul paramètre dans l'en-tête du play la désactive — utile quand la vitesse importe et que les faits ne sont pas nécessaires."
    instructions="[
                  {
                    \"instruction\": \"Ajoutez <span class=\\\"bold-green-text\\\">gather_facts: no</span> dans l'en-tête du play pour ignorer la tâche setup implicite.\",
                    \"command\": \"- name: play sans faits\\n  hosts: all\\n  gather_facts: no\\n  tasks:\\n    - name: tâche rapide\\n      command: uptime\"
                  },
                  {
                    \"instruction\": \"Si les faits sont nécessaires plus tard dans le même playbook, exécutez le module <span class=\\\"bold-green-text\\\">setup</span> explicitement.\",
                    \"command\": \"- name: collecter les faits manuellement si nécessaire\\n  setup:\"
                  }
                ]"
    answer_a="facts: disabled"
    answer_b="collect_facts: false"
    answer_c="gather_facts: no"  # Correct answer
    answer_d="setup: skip"
    ;;
  *)
    question="Which play header parameter disables automatic fact gathering for a play?"
    hint="By default every play runs a hidden fact-gathering task first. A single parameter in the play header turns this off — useful when speed matters and facts are not needed."
    instructions="[
                  {
                    \"instruction\": \"Add <span class=\\\"bold-green-text\\\">gather_facts: no</span> to the play header to skip the implicit setup task.\",
                    \"command\": \"- name: play without facts\\n  hosts: all\\n  gather_facts: no\\n  tasks:\\n    - name: quick task\\n      command: uptime\"
                  },
                  {
                    \"instruction\": \"If facts are needed later in the same playbook, run the <span class=\\\"bold-green-text\\\">setup</span> module explicitly.\",
                    \"command\": \"- name: manually gather facts when needed\\n  setup:\"
                  }
                ]"
    answer_a="facts: disabled"
    answer_b="collect_facts: false"
    answer_c="gather_facts: no"  # Correct answer
    answer_d="setup: skip"
    ;;
esac

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
  "solution": "'"$answer_c"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
