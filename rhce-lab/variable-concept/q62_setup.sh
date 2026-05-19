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
    question="Which notation is PREFERRED when addressing values inside the ansible_facts variable?"
    hint="The Ansible documentation explicitly recommends one of these two notations over the other. It avoids conflicts with Python attribute access."
    instructions="[
                  {
                    \"instruction\": \"Two valid notations exist. The <span class=\\\"bold-green-text\\\">square brackets</span> notation is the recommended approach.\",
                    \"command\": \"# Preferred (square brackets):\\n{{ ansible_facts['default_ipv4']['address'] }}\\n\\n# Also valid but not preferred (dotted notation):\\n{{ ansible_facts.default_ipv4.address }}\"
                  },
                  {
                    \"instruction\": \"Use the preferred notation in a playbook task to display the main IP address.\",
                    \"command\": \"- name: show IP address\\n  debug:\\n    msg: \\\"IP is {{ ansible_facts['default_ipv4']['address'] }}\\\"\"
                  }
                ]"
    answer_a="Square brackets notation: ansible_facts['hostname']"  # Correct answer
    answer_b="Dotted notation: ansible_facts.hostname"
    answer_c="Dollar sign notation: \$ansible_facts.hostname"
    answer_d="Both notations are equally recommended"
    ;;
  "fr")
    question="Quelle notation est PRÉFÉRÉE pour accéder aux valeurs dans la variable ansible_facts ?"
    hint="La documentation Ansible recommande explicitement l'une de ces deux notations. Elle évite les conflits avec l'accès aux attributs Python."
    instructions="[
                  {
                    \"instruction\": \"Deux notations valides existent. La notation avec des <span class=\\\"bold-green-text\\\">crochets</span> est l'approche recommandée.\",
                    \"command\": \"# Préférée (crochets) :\\n{{ ansible_facts['default_ipv4']['address'] }}\\n\\n# Aussi valide mais non préférée (notation pointée) :\\n{{ ansible_facts.default_ipv4.address }}\"
                  },
                  {
                    \"instruction\": \"Utilisez la notation préférée dans une tâche pour afficher l'adresse IP principale.\",
                    \"command\": \"- name: afficher l'adresse IP\\n  debug:\\n    msg: \\\"IP : {{ ansible_facts['default_ipv4']['address'] }}\\\"\"
                  }
                ]"
    answer_a="Notation crochets : ansible_facts['hostname']"  # Correct answer
    answer_b="Notation pointée : ansible_facts.hostname"
    answer_c="Notation dollar : \$ansible_facts.hostname"
    answer_d="Les deux notations sont également recommandées"
    ;;
  *)
    question="Which notation is PREFERRED when addressing values inside the ansible_facts variable?"
    hint="The Ansible documentation explicitly recommends one of these two notations over the other. It avoids conflicts with Python attribute access."
    instructions="[
                  {
                    \"instruction\": \"Two valid notations exist. The <span class=\\\"bold-green-text\\\">square brackets</span> notation is the recommended approach.\",
                    \"command\": \"# Preferred (square brackets):\\n{{ ansible_facts['default_ipv4']['address'] }}\\n\\n# Also valid but not preferred (dotted notation):\\n{{ ansible_facts.default_ipv4.address }}\"
                  },
                  {
                    \"instruction\": \"Use the preferred notation in a playbook task to display the main IP address.\",
                    \"command\": \"- name: show IP address\\n  debug:\\n    msg: \\\"IP is {{ ansible_facts['default_ipv4']['address'] }}\\\"\"
                  }
                ]"
    answer_a="Square brackets notation: ansible_facts['hostname']"  # Correct answer
    answer_b="Dotted notation: ansible_facts.hostname"
    answer_c="Dollar sign notation: \$ansible_facts.hostname"
    answer_d="Both notations are equally recommended"
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
  "solution": "'"$answer_a"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
