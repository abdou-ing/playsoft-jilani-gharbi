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
    question="Which Ansible module is used in an ad-hoc command to test connectivity to managed hosts?"
    hint="Run an ad-hoc command against your inventory using each module name. Only one of them is designed to test the Ansible connection itself and returns pong on success."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">ping</span> module is a built-in Ansible module that verifies the SSH connection and Python interpreter on each managed host.\",
                    \"command\": \"ansible all -m ping\\n# Success output:\\nnode1 | SUCCESS => {\\n    \\\"ping\\\": \\\"pong\\\"\\n}\"
                  },
                  {
                    \"instruction\": \"This is NOT an ICMP ping. It uses SSH and Python to confirm Ansible can fully communicate with the host.\",
                    \"command\": \"# -m specifies the module name\\nansible webservers -m ping\"
                  }
                ]"
    answer_a="icmp"
    answer_b="network"
    answer_c="check"
    answer_d="ping"  # Correct answer
    ;;
  "fr")
    question="Quel module Ansible est utilisé dans une commande ad-hoc pour tester la connectivité aux hôtes gérés ?"
    hint="Exécutez une commande ad-hoc sur votre inventaire en utilisant chaque nom de module. Un seul est conçu pour tester la connexion Ansible elle-même et retourne pong en cas de succès."
    instructions="[
                  {
                    \"instruction\": \"Le module <span class=\\\"bold-green-text\\\">ping</span> est un module Ansible intégré qui vérifie la connexion SSH et l'interpréteur Python sur chaque hôte géré.\",
                    \"command\": \"ansible all -m ping\\n# Sortie en cas de succès :\\nnode1 | SUCCESS => {\\n    \\\"ping\\\": \\\"pong\\\"\\n}\"
                  },
                  {
                    \"instruction\": \"Ce n'est PAS un ping ICMP. Il utilise SSH et Python pour confirmer qu'Ansible peut communiquer entièrement avec l'hôte.\",
                    \"command\": \"# -m spécifie le nom du module\\nansible webservers -m ping\"
                  }
                ]"
    answer_a="icmp"
    answer_b="network"
    answer_c="check"
    answer_d="ping"  # Correct answer
    ;;
  *)
    question="Which Ansible module is used in an ad-hoc command to test connectivity to managed hosts?"
    hint="Run an ad-hoc command against your inventory using each module name. Only one of them is designed to test the Ansible connection itself and returns pong on success."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">ping</span> module is a built-in Ansible module that verifies the SSH connection and Python interpreter on each managed host.\",
                    \"command\": \"ansible all -m ping\\n# Success output:\\nnode1 | SUCCESS => {\\n    \\\"ping\\\": \\\"pong\\\"\\n}\"
                  },
                  {
                    \"instruction\": \"This is NOT an ICMP ping. It uses SSH and Python to confirm Ansible can fully communicate with the host.\",
                    \"command\": \"# -m specifies the module name\\nansible webservers -m ping\"
                  }
                ]"
    answer_a="icmp"
    answer_b="network"
    answer_c="check"
    answer_d="ping"  # Correct answer
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
