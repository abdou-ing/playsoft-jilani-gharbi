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
    question="After fact gathering runs on a managed host, where are all collected system properties stored?"
    hint="Since Ansible 2.5 all gathered facts are kept in one central variable — not injected individually as separate top-level variables."
    instructions="[
                  {
                    \"instruction\": \"Use the <span class=\\\"bold-green-text\\\">debug</span> module with the <span class=\\\"bold-green-text\\\">var</span> argument to display all gathered facts.\",
                    \"command\": \"- name: show all facts\\n  hosts: all\\n  tasks:\\n    - name: display gathered facts\\n      debug:\\n        var: ansible_facts\"
                  },
                  {
                    \"instruction\": \"Access a specific value inside the facts dictionary using square bracket notation.\",
                    \"command\": \"- name: show hostname\\n  debug:\\n    msg: \\\"Host is {{ ansible_facts['hostname'] }}\\\"\"
                  }
                ]"
    answer_a="ansible_vars"
    answer_b="host_info"
    answer_c="ansible_facts"  # Correct answer
    answer_d="system_facts"
    ;;
  "fr")
    question="Après la collecte des faits sur un hôte géré, où sont stockées toutes les propriétés système collectées ?"
    hint="Depuis Ansible 2.5, tous les faits collectés sont conservés dans une seule variable centrale — ils ne sont plus injectés individuellement comme variables séparées."
    instructions="[
                  {
                    \"instruction\": \"Utilisez le module <span class=\\\"bold-green-text\\\">debug</span> avec l'argument <span class=\\\"bold-green-text\\\">var</span> pour afficher tous les faits collectés.\",
                    \"command\": \"- name: afficher tous les faits\\n  hosts: all\\n  tasks:\\n    - name: afficher les faits\\n      debug:\\n        var: ansible_facts\"
                  },
                  {
                    \"instruction\": \"Accédez à une valeur spécifique dans le dictionnaire de faits avec la notation entre crochets.\",
                    \"command\": \"- name: afficher le nom d'hote\\n  debug:\\n    msg: \\\"Hote : {{ ansible_facts['hostname'] }}\\\"\"
                  }
                ]"
    answer_a="ansible_vars"
    answer_b="host_info"
    answer_c="ansible_facts"  # Correct answer
    answer_d="system_facts"
    ;;
  *)
    question="After fact gathering runs on a managed host, where are all collected system properties stored?"
    hint="Since Ansible 2.5 all gathered facts are kept in one central variable — not injected individually as separate top-level variables."
    instructions="[
                  {
                    \"instruction\": \"Use the <span class=\\\"bold-green-text\\\">debug</span> module with the <span class=\\\"bold-green-text\\\">var</span> argument to display all gathered facts.\",
                    \"command\": \"- name: show all facts\\n  hosts: all\\n  tasks:\\n    - name: display gathered facts\\n      debug:\\n        var: ansible_facts\"
                  },
                  {
                    \"instruction\": \"Access a specific value inside the facts dictionary using square bracket notation.\",
                    \"command\": \"- name: show hostname\\n  debug:\\n    msg: \\\"Host is {{ ansible_facts['hostname'] }}\\\"\"
                  }
                ]"
    answer_a="ansible_vars"
    answer_b="host_info"
    answer_c="ansible_facts"  # Correct answer
    answer_d="system_facts"
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
