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
    question="Which of the following is NOT a valid Ansible variable name?"
    hint="Variable names can only contain letters, numbers, and underscores. Check which character in one of the options is not allowed."
    instructions="[
                  {
                    \"instruction\": \"Variable names must start with a letter and contain only letters, numbers, and <span class=\\\"bold-green-text\\\">underscores</span>. Hyphens and spaces are not allowed.\",
                    \"command\": \"# Valid variable names:\\nvars:\\n  my_package: httpd\\n  myPackage: nginx\\n  my_package_1: vsftpd\\n\\n# Invalid (hyphen not allowed):\\n  my-package: httpd  # ERROR\"
                  },
                  {
                    \"instruction\": \"Variable names are also <span class=\\\"bold-green-text\\\">case sensitive</span>: my_var and My_Var are two different variables.\",
                    \"command\": \"- name: use a valid variable\\n  yum:\\n    name: \\\"{{ my_package }}\\\"\\n    state: latest\"
                  }
                ]"
    answer_a="my_package"
    answer_b="my-package"  # Correct answer
    answer_c="myPackage"
    answer_d="my_package_1"
    ;;
  "fr")
    question="Lequel des noms suivants N'EST PAS un nom de variable Ansible valide ?"
    hint="Les noms de variables ne peuvent contenir que des lettres, des chiffres et des tirets bas. Vérifiez quel caractère dans l'une des options n'est pas autorisé."
    instructions="[
                  {
                    \"instruction\": \"Les noms de variables doivent commencer par une lettre et ne contenir que des lettres, des chiffres et des <span class=\\\"bold-green-text\\\">tirets bas</span>. Les traits d'union et les espaces ne sont pas autorisés.\",
                    \"command\": \"# Noms de variables valides :\\nvars:\\n  my_package: httpd\\n  myPackage: nginx\\n  my_package_1: vsftpd\\n\\n# Invalide (trait d'union interdit) :\\n  my-package: httpd  # ERREUR\"
                  },
                  {
                    \"instruction\": \"Les noms de variables sont aussi <span class=\\\"bold-green-text\\\">sensibles à la casse</span> : my_var et My_Var sont deux variables différentes.\",
                    \"command\": \"- name: utiliser une variable valide\\n  yum:\\n    name: \\\"{{ my_package }}\\\"\\n    state: latest\"
                  }
                ]"
    answer_a="my_package"
    answer_b="my-package"  # Correct answer
    answer_c="myPackage"
    answer_d="my_package_1"
    ;;
  *)
    question="Which of the following is NOT a valid Ansible variable name?"
    hint="Variable names can only contain letters, numbers, and underscores. Check which character in one of the options is not allowed."
    instructions="[
                  {
                    \"instruction\": \"Variable names must start with a letter and contain only letters, numbers, and <span class=\\\"bold-green-text\\\">underscores</span>. Hyphens and spaces are not allowed.\",
                    \"command\": \"# Valid variable names:\\nvars:\\n  my_package: httpd\\n  myPackage: nginx\\n  my_package_1: vsftpd\\n\\n# Invalid (hyphen not allowed):\\n  my-package: httpd  # ERROR\"
                  },
                  {
                    \"instruction\": \"Variable names are also <span class=\\\"bold-green-text\\\">case sensitive</span>: my_var and My_Var are two different variables.\",
                    \"command\": \"- name: use a valid variable\\n  yum:\\n    name: \\\"{{ my_package }}\\\"\\n    state: latest\"
                  }
                ]"
    answer_a="my_package"
    answer_b="my-package"  # Correct answer
    answer_c="myPackage"
    answer_d="my_package_1"
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
  "solution": "'"$answer_b"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
