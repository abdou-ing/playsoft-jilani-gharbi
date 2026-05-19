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
    question="Which Ansible magic variable contains ALL hosts in the inventory together with their assigned variables?"
    hint="Magic variables are set automatically by Ansible. One of them acts as a dictionary of every host — useful when you need to read a variable from a different host inside a running task."
    instructions="[
                  {
                    \"instruction\": \"Use <span class=\\\"bold-green-text\\\">hostvars</span> to access a variable from another host while a task is running on the current host.\",
                    \"command\": \"# Read ansible2's IP address from a task running on ansible1:\\n{{ hostvars['ansible2']['ansible_default_ipv4']['address'] }}\\n\\n# Inspect hostvars for a host via ad-hoc command:\\nansible localhost -m debug -a 'var=hostvars[\\\"ansible1\\\"]'\"
                  },
                  {
                    \"instruction\": \"Other key magic variables and their purpose.\",
                    \"command\": \"# groups           -> all groups in inventory\\n# group_names     -> groups the current host belongs to\\n# inventory_hostname -> current host's inventory name\"
                  }
                ]"
    answer_a="hostvars"  # Correct answer
    answer_b="groups"
    answer_c="group_names"
    answer_d="inventory_hostname"
    ;;
  "fr")
    question="Quelle variable magique Ansible contient TOUS les hôtes de l'inventaire avec leurs variables assignées ?"
    hint="Les variables magiques sont définies automatiquement par Ansible. L'une d'elles agit comme un dictionnaire de tous les hôtes — utile pour lire une variable d'un autre hôte depuis une tâche en cours."
    instructions="[
                  {
                    \"instruction\": \"Utilisez <span class=\\\"bold-green-text\\\">hostvars</span> pour accéder à une variable d'un autre hôte pendant qu'une tâche s'exécute sur l'hôte courant.\",
                    \"command\": \"# Lire l'adresse IP de ansible2 depuis une tâche sur ansible1 :\\n{{ hostvars['ansible2']['ansible_default_ipv4']['address'] }}\\n\\n# Inspecter hostvars via une commande ad-hoc :\\nansible localhost -m debug -a 'var=hostvars[\\\"ansible1\\\"]'\"
                  },
                  {
                    \"instruction\": \"Autres variables magiques importantes et leur rôle.\",
                    \"command\": \"# groups           -> tous les groupes de l'inventaire\\n# group_names     -> groupes dont fait partie l'hôte courant\\n# inventory_hostname -> nom de l'hôte courant dans l'inventaire\"
                  }
                ]"
    answer_a="hostvars"  # Correct answer
    answer_b="groups"
    answer_c="group_names"
    answer_d="inventory_hostname"
    ;;
  *)
    question="Which Ansible magic variable contains ALL hosts in the inventory together with their assigned variables?"
    hint="Magic variables are set automatically by Ansible. One of them acts as a dictionary of every host — useful when you need to read a variable from a different host inside a running task."
    instructions="[
                  {
                    \"instruction\": \"Use <span class=\\\"bold-green-text\\\">hostvars</span> to access a variable from another host while a task is running on the current host.\",
                    \"command\": \"# Read ansible2's IP address from a task running on ansible1:\\n{{ hostvars['ansible2']['ansible_default_ipv4']['address'] }}\\n\\n# Inspect hostvars for a host via ad-hoc command:\\nansible localhost -m debug -a 'var=hostvars[\\\"ansible1\\\"]'\"
                  },
                  {
                    \"instruction\": \"Other key magic variables and their purpose.\",
                    \"command\": \"# groups           -> all groups in inventory\\n# group_names     -> groups the current host belongs to\\n# inventory_hostname -> current host's inventory name\"
                  }
                ]"
    answer_a="hostvars"  # Correct answer
    answer_b="groups"
    answer_c="group_names"
    answer_d="inventory_hostname"
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
