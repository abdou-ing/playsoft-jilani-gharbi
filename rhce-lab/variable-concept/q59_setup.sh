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
    question="What are the three types of variables in Ansible?"
    hint="Think about variables that are discovered automatically, defined by the user, and managed internally by Ansible itself."
    instructions="[
                  {
                    \"instruction\": \"Ansible defines three distinct variable types: <span class=\\\"bold-green-text\\\">fact</span>, <span class=\\\"bold-green-text\\\">variable</span>, and <span class=\\\"bold-green-text\\\">magic variable</span>.\",
                    \"command\": \"# fact         -> discovered from the managed system\\n# variable     -> defined by the user in vars:, vars_files:, group_vars\\n# magic        -> set internally by Ansible (hostvars, groups, inventory_hostname)\"
                  },
                  {
                    \"instruction\": \"Display all gathered facts to explore the fact variable type.\",
                    \"command\": \"ansible all -m setup | head -40\"
                  }
                ]"
    answer_a="fact, variable, magic variable"  # Correct answer
    answer_b="static, dynamic, runtime"
    answer_c="global, local, environment"
    answer_d="play, role, host"
    ;;
  "fr")
    question="Quels sont les trois types de variables dans Ansible ?"
    hint="Pensez aux variables découvertes automatiquement, définies par l'utilisateur, et gérées en interne par Ansible."
    instructions="[
                  {
                    \"instruction\": \"Ansible définit trois types de variables distincts : <span class=\\\"bold-green-text\\\">fact</span>, <span class=\\\"bold-green-text\\\">variable</span> et <span class=\\\"bold-green-text\\\">magic variable</span>.\",
                    \"command\": \"# fact         -> découverte depuis le système géré\\n# variable     -> définie par l'utilisateur dans vars:, vars_files:, group_vars\\n# magic        -> définie en interne par Ansible (hostvars, groups, inventory_hostname)\"
                  },
                  {
                    \"instruction\": \"Affichez tous les faits collectés pour explorer le type fact.\",
                    \"command\": \"ansible all -m setup | head -40\"
                  }
                ]"
    answer_a="fact, variable, magic variable"  # Correct answer
    answer_b="static, dynamic, runtime"
    answer_c="global, local, environment"
    answer_d="play, role, host"
    ;;
  *)
    question="What are the three types of variables in Ansible?"
    hint="Think about variables that are discovered automatically, defined by the user, and managed internally by Ansible itself."
    instructions="[
                  {
                    \"instruction\": \"Ansible defines three distinct variable types: <span class=\\\"bold-green-text\\\">fact</span>, <span class=\\\"bold-green-text\\\">variable</span>, and <span class=\\\"bold-green-text\\\">magic variable</span>.\",
                    \"command\": \"# fact         -> discovered from the managed system\\n# variable     -> defined by the user in vars:, vars_files:, group_vars\\n# magic        -> set internally by Ansible (hostvars, groups, inventory_hostname)\"
                  },
                  {
                    \"instruction\": \"Display all gathered facts to explore the fact variable type.\",
                    \"command\": \"ansible all -m setup | head -40\"
                  }
                ]"
    answer_a="fact, variable, magic variable"  # Correct answer
    answer_b="static, dynamic, runtime"
    answer_c="global, local, environment"
    answer_d="play, role, host"
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
