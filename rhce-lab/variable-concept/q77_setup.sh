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
    question="In an Ansible inventory file, how do you define a group that contains OTHER groups as its members?"
    hint="Look at the inventory file syntax. There is a special keyword you append to a group name with a colon to declare that its members are groups, not hosts."
    instructions="[
                  {
                    \"instruction\": \"Use the <span class=\\\"bold-green-text\\\">:children</span> suffix on a group name to declare that its members are other groups.\",
                    \"command\": \"[webservers:children]\\nprod\\nbalancers\"
                  },
                  {
                    \"instruction\": \"In this example, the webservers group contains every host from both the prod and balancers groups.\",
                    \"command\": \"[prod]\\nnode3\\nnode4\\n\\n[balancers]\\nnode5\\n\\n[webservers:children]\\nprod\\nbalancers\"
                  }
                ]"
    answer_a="[webservers:members]"
    answer_b="[webservers:nested]"
    answer_c="[webservers:subgroups]"
    answer_d="[webservers:children]"  # Correct answer
    ;;
  "fr")
    question="Dans un fichier d'inventaire Ansible, comment définir un groupe qui contient D'AUTRES groupes comme membres ?"
    hint="Regardez la syntaxe du fichier d'inventaire. Il existe un mot-clé spécial que vous ajoutez au nom d'un groupe avec un deux-points pour déclarer que ses membres sont des groupes, pas des hôtes."
    instructions="[
                  {
                    \"instruction\": \"Utilisez le suffixe <span class=\\\"bold-green-text\\\">:children</span> sur un nom de groupe pour déclarer que ses membres sont d'autres groupes.\",
                    \"command\": \"[webservers:children]\\nprod\\nbalancers\"
                  },
                  {
                    \"instruction\": \"Dans cet exemple, le groupe webservers contient tous les hôtes des groupes prod et balancers.\",
                    \"command\": \"[prod]\\nnode3\\nnode4\\n\\n[balancers]\\nnode5\\n\\n[webservers:children]\\nprod\\nbalancers\"
                  }
                ]"
    answer_a="[webservers:members]"
    answer_b="[webservers:nested]"
    answer_c="[webservers:subgroups]"
    answer_d="[webservers:children]"  # Correct answer
    ;;
  *)
    question="In an Ansible inventory file, how do you define a group that contains OTHER groups as its members?"
    hint="Look at the inventory file syntax. There is a special keyword you append to a group name with a colon to declare that its members are groups, not hosts."
    instructions="[
                  {
                    \"instruction\": \"Use the <span class=\\\"bold-green-text\\\">:children</span> suffix on a group name to declare that its members are other groups.\",
                    \"command\": \"[webservers:children]\\nprod\\nbalancers\"
                  },
                  {
                    \"instruction\": \"In this example, the webservers group contains every host from both the prod and balancers groups.\",
                    \"command\": \"[prod]\\nnode3\\nnode4\\n\\n[balancers]\\nnode5\\n\\n[webservers:children]\\nprod\\nbalancers\"
                  }
                ]"
    answer_a="[webservers:members]"
    answer_b="[webservers:nested]"
    answer_c="[webservers:subgroups]"
    answer_d="[webservers:children]"  # Correct answer
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
