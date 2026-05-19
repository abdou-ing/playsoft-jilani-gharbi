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
    question="Which variable definition has the HIGHEST precedence in Ansible?"
    hint="The most specific variable always wins. Think about where a variable is defined closest to actual runtime execution."
    instructions="[
                  {
                    \"instruction\": \"Variables passed on the command line with <span class=\\\"bold-green-text\\\">-e</span> have the highest precedence and override everything else.\",
                    \"command\": \"# Overrides any vars: defined in the playbook:\\nansible-playbook site.yml -e \\\"my_var=override_value\\\"\\n\\n# Precedence order (highest to lowest):\\n# 1. Command line: -e key=value\\n# 2. Playbook vars: section\\n# 3. Inventory variables (group_vars, host_vars)\"
                  },
                  {
                    \"instruction\": \"Verify which value wins by using the debug module in a playbook.\",
                    \"command\": \"- name: check variable value\\n  debug:\\n    msg: \\\"Value is {{ my_var }}\\\"\"
                  }
                ]"
    answer_a="Variables defined in a playbook vars: section"
    answer_b="Variables defined in group_vars files"
    answer_c="Variables defined in host_vars files"
    answer_d="Variables passed on the command line with -e key=value"  # Correct answer
    ;;
  "fr")
    question="Quelle définition de variable a la PLUS HAUTE priorité dans Ansible ?"
    hint="La variable la plus spécifique l'emporte toujours. Pensez à l'endroit où une variable est définie le plus près de l'exécution réelle."
    instructions="[
                  {
                    \"instruction\": \"Les variables passées en ligne de commande avec <span class=\\\"bold-green-text\\\">-e</span> ont la priorité la plus haute et remplacent tout le reste.\",
                    \"command\": \"# Remplace tout vars: défini dans le playbook :\\nansible-playbook site.yml -e \\\"my_var=valeur_override\\\"\\n\\n# Ordre de priorité (du plus élevé au plus bas) :\\n# 1. Ligne de commande : -e key=value\\n# 2. Section vars: du playbook\\n# 3. Variables d'inventaire (group_vars, host_vars)\"
                  },
                  {
                    \"instruction\": \"Vérifiez quelle valeur l'emporte avec le module debug dans un playbook.\",
                    \"command\": \"- name: vérifier la valeur de la variable\\n  debug:\\n    msg: \\\"Valeur : {{ my_var }}\\\"\"
                  }
                ]"
    answer_a="Variables définies dans la section vars: d'un playbook"
    answer_b="Variables définies dans les fichiers group_vars"
    answer_c="Variables définies dans les fichiers host_vars"
    answer_d="Variables passées en ligne de commande avec -e key=value"  # Correct answer
    ;;
  *)
    question="Which variable definition has the HIGHEST precedence in Ansible?"
    hint="The most specific variable always wins. Think about where a variable is defined closest to actual runtime execution."
    instructions="[
                  {
                    \"instruction\": \"Variables passed on the command line with <span class=\\\"bold-green-text\\\">-e</span> have the highest precedence and override everything else.\",
                    \"command\": \"# Overrides any vars: defined in the playbook:\\nansible-playbook site.yml -e \\\"my_var=override_value\\\"\\n\\n# Precedence order (highest to lowest):\\n# 1. Command line: -e key=value\\n# 2. Playbook vars: section\\n# 3. Inventory variables (group_vars, host_vars)\"
                  },
                  {
                    \"instruction\": \"Verify which value wins by using the debug module in a playbook.\",
                    \"command\": \"- name: check variable value\\n  debug:\\n    msg: \\\"Value is {{ my_var }}\\\"\"
                  }
                ]"
    answer_a="Variables defined in a playbook vars: section"
    answer_b="Variables defined in group_vars files"
    answer_c="Variables defined in host_vars files"
    answer_d="Variables passed on the command line with -e key=value"  # Correct answer
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
