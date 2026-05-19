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
    question="Which command is used to execute an Ansible playbook?"
    hint="Try each command on your control node with a simple playbook. Only one of them is the correct binary for running YAML playbooks."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible-playbook</span> is the command that reads and executes a YAML playbook file against your inventory.\",
                    \"command\": \"ansible-playbook site.yml\\n\\n# Common options:\\nansible-playbook site.yml -v          # verbose\\nansible-playbook site.yml --check     # dry run\\nansible-playbook site.yml --syntax-check  # validate YAML\"
                  },
                  {
                    \"instruction\": \"Do not confuse ansible-playbook (runs a playbook file) with ansible (runs a single ad-hoc module).\",
                    \"command\": \"# ad-hoc: runs one module directly\\nansible all -m ping\\n\\n# playbook: runs a full YAML file\\nansible-playbook site.yml\"
                  }
                ]"
    answer_a="ansible run playbook.yml"
    answer_b="ansible-play playbook.yml"
    answer_c="ansible exec playbook.yml"
    answer_d="ansible-playbook playbook.yml"  # Correct answer
    ;;
  "fr")
    question="Quelle commande est utilisée pour exécuter un playbook Ansible ?"
    hint="Essayez chaque commande sur votre nœud de contrôle avec un playbook simple. Une seule est le binaire correct pour exécuter des playbooks YAML."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible-playbook</span> est la commande qui lit et exécute un fichier de playbook YAML contre votre inventaire.\",
                    \"command\": \"ansible-playbook site.yml\\n\\n# Options courantes :\\nansible-playbook site.yml -v          # verbeux\\nansible-playbook site.yml --check     # simulation\\nansible-playbook site.yml --syntax-check  # valider le YAML\"
                  },
                  {
                    \"instruction\": \"Ne pas confondre ansible-playbook (exécute un fichier playbook) avec ansible (exécute un seul module ad-hoc).\",
                    \"command\": \"# ad-hoc : exécute un module directement\\nansible all -m ping\\n\\n# playbook : exécute un fichier YAML complet\\nansible-playbook site.yml\"
                  }
                ]"
    answer_a="ansible run playbook.yml"
    answer_b="ansible-play playbook.yml"
    answer_c="ansible exec playbook.yml"
    answer_d="ansible-playbook playbook.yml"  # Correct answer
    ;;
  *)
    question="Which command is used to execute an Ansible playbook?"
    hint="Try each command on your control node with a simple playbook. Only one of them is the correct binary for running YAML playbooks."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible-playbook</span> is the command that reads and executes a YAML playbook file against your inventory.\",
                    \"command\": \"ansible-playbook site.yml\\n\\n# Common options:\\nansible-playbook site.yml -v          # verbose\\nansible-playbook site.yml --check     # dry run\\nansible-playbook site.yml --syntax-check  # validate YAML\"
                  },
                  {
                    \"instruction\": \"Do not confuse ansible-playbook (runs a playbook file) with ansible (runs a single ad-hoc module).\",
                    \"command\": \"# ad-hoc: runs one module directly\\nansible all -m ping\\n\\n# playbook: runs a full YAML file\\nansible-playbook site.yml\"
                  }
                ]"
    answer_a="ansible run playbook.yml"
    answer_b="ansible-play playbook.yml"
    answer_c="ansible exec playbook.yml"
    answer_d="ansible-playbook playbook.yml"  # Correct answer
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
  "solution": "'"$answer_d"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
