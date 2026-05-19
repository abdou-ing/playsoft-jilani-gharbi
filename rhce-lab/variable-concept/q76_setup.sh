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
    question="In ansible.cfg, which section is used to define the inventory file path, roles directory, and remote user?"
    hint="Open an ansible.cfg file and look at the section headers. Only one section is the main configuration block where most settings like inventory, roles_path, and remote_user belong."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">[defaults]</span> section is the main block in ansible.cfg. It holds the most commonly used settings.\",
                    \"command\": \"[defaults]\\ninventory = inventory\\nroles_path = /home/admin/ansible/roles\\nremote_user = admin\"
                  },
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">[privilege_escalation]</span> section is separate and only holds become-related settings.\",
                    \"command\": \"[privilege_escalation]\\nbecome = true\\nbecome_method = sudo\\nbecome_user = root\\nbecome_ask_pass = false\"
                  }
                ]"
    answer_a="[inventory]"
    answer_b="[privilege_escalation]"
    answer_c="[defaults]"  # Correct answer
    answer_d="[connections]"
    ;;
  "fr")
    question="Dans ansible.cfg, quelle section est utilisée pour définir le chemin du fichier d'inventaire, le répertoire des rôles et l'utilisateur distant ?"
    hint="Ouvrez un fichier ansible.cfg et regardez les en-têtes de section. Une seule section est le bloc de configuration principal où la plupart des paramètres comme inventory, roles_path et remote_user appartiennent."
    instructions="[
                  {
                    \"instruction\": \"La section <span class=\\\"bold-green-text\\\">[defaults]</span> est le bloc principal d'ansible.cfg. Elle contient les paramètres les plus couramment utilisés.\",
                    \"command\": \"[defaults]\\ninventory = inventory\\nroles_path = /home/admin/ansible/roles\\nremote_user = admin\"
                  },
                  {
                    \"instruction\": \"La section <span class=\\\"bold-green-text\\\">[privilege_escalation]</span> est séparée et contient uniquement les paramètres liés à become.\",
                    \"command\": \"[privilege_escalation]\\nbecome = true\\nbecome_method = sudo\\nbecome_user = root\\nbecome_ask_pass = false\"
                  }
                ]"
    answer_a="[inventory]"
    answer_b="[privilege_escalation]"
    answer_c="[defaults]"  # Correct answer
    answer_d="[connections]"
    ;;
  *)
    question="In ansible.cfg, which section is used to define the inventory file path, roles directory, and remote user?"
    hint="Open an ansible.cfg file and look at the section headers. Only one section is the main configuration block where most settings like inventory, roles_path, and remote_user belong."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">[defaults]</span> section is the main block in ansible.cfg. It holds the most commonly used settings.\",
                    \"command\": \"[defaults]\\ninventory = inventory\\nroles_path = /home/admin/ansible/roles\\nremote_user = admin\"
                  },
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">[privilege_escalation]</span> section is separate and only holds become-related settings.\",
                    \"command\": \"[privilege_escalation]\\nbecome = true\\nbecome_method = sudo\\nbecome_user = root\\nbecome_ask_pass = false\"
                  }
                ]"
    answer_a="[inventory]"
    answer_b="[privilege_escalation]"
    answer_c="[defaults]"  # Correct answer
    answer_d="[connections]"
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
