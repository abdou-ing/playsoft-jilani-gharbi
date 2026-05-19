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
    question="Given this inventory file, how many hosts are in the webservers group?\n\n[webservers]\nweb01\nweb02\nweb03\n\n[dbservers]\ndb01\ndb02"
    hint="Run the command on your control node to list hosts in a group. Count the lines in the output that are actual hostnames."
    instructions="[
                  {
                    \"instruction\": \"Use <span class=\\\"bold-green-text\\\">ansible webservers --list-hosts</span> to display every host that belongs to a group.\",
                    \"command\": \"ansible webservers --list-hosts\\n# Output:\\n  hosts (3):\\n    web01\\n    web02\\n    web03\"
                  },
                  {
                    \"instruction\": \"The number in parentheses on the first line tells you the exact host count at a glance.\",
                    \"command\": \"# The (3) confirms 3 hosts are in the webservers group\"
                  }
                ]"
    answer_a="1"
    answer_b="2"
    answer_c="3"  # Correct answer
    answer_d="4"
    ;;
  "fr")
    question="D'après ce fichier d'inventaire, combien d'hôtes sont dans le groupe webservers ?\n\n[webservers]\nweb01\nweb02\nweb03\n\n[dbservers]\ndb01\ndb02"
    hint="Exécutez la commande sur votre nœud de contrôle pour lister les hôtes d'un groupe. Comptez les lignes dans la sortie qui sont des noms d'hôtes réels."
    instructions="[
                  {
                    \"instruction\": \"Utilisez <span class=\\\"bold-green-text\\\">ansible webservers --list-hosts</span> pour afficher chaque hôte appartenant à un groupe.\",
                    \"command\": \"ansible webservers --list-hosts\\n# Sortie :\\n  hosts (3):\\n    web01\\n    web02\\n    web03\"
                  },
                  {
                    \"instruction\": \"Le nombre entre parenthèses sur la première ligne indique le nombre exact d'hôtes en un coup d'œil.\",
                    \"command\": \"# Le (3) confirme que 3 hôtes sont dans le groupe webservers\"
                  }
                ]"
    answer_a="1"
    answer_b="2"
    answer_c="3"  # Correct answer
    answer_d="4"
    ;;
  *)
    question="Given this inventory file, how many hosts are in the webservers group?\n\n[webservers]\nweb01\nweb02\nweb03\n\n[dbservers]\ndb01\ndb02"
    hint="Run the command on your control node to list hosts in a group. Count the lines in the output that are actual hostnames."
    instructions="[
                  {
                    \"instruction\": \"Use <span class=\\\"bold-green-text\\\">ansible webservers --list-hosts</span> to display every host that belongs to a group.\",
                    \"command\": \"ansible webservers --list-hosts\\n# Output:\\n  hosts (3):\\n    web01\\n    web02\\n    web03\"
                  },
                  {
                    \"instruction\": \"The number in parentheses on the first line tells you the exact host count at a glance.\",
                    \"command\": \"# The (3) confirms 3 hosts are in the webservers group\"
                  }
                ]"
    answer_a="1"
    answer_b="2"
    answer_c="3"  # Correct answer
    answer_d="4"
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
  "plateforme_required": "container",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
