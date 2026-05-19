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
    question="What is wrong with the variable definition in this playbook?\n\n---\n- name: configure web server\n  hosts: all\n  vars:\n    web-package: httpd\n    web-service: httpd\n  tasks:\n    - name: install package\n      yum:\n        name: {{ web-package }}\n        state: latest"
    hint="Ansible variable names have strict character rules. Look at the vars: section — focus on the names themselves, not the values."
    instructions="[
                  {
                    \"instruction\": \"Variable names can contain only <span class=\\\"bold-green-text\\\">letters, numbers, and underscores</span>. Hyphens (-) are not allowed.\",
                    \"command\": \"# Fix: replace hyphens with underscores\\nvars:\\n  web_package: httpd\\n  web_service: httpd\"
                  },
                  {
                    \"instruction\": \"After fixing the names, also add double quotes around the reference since the value starts with {{ }}.\",
                    \"command\": \"        name: \\\"{{ web_package }}\\\"\"
                  }
                ]"
    answer_a="The value httpd must be wrapped in double quotes"
    answer_b="The hosts: all target is too broad and should name a group"
    answer_c="The variable names web-package and web-service contain hyphens which are not allowed"  # Correct answer
    answer_d="The yum module is deprecated, apt should be used instead"
    ;;
  "fr")
    question="Qu'est-ce qui ne va pas avec la définition des variables dans ce playbook ?\n\n---\n- name: configurer le serveur web\n  hosts: all\n  vars:\n    web-package: httpd\n    web-service: httpd\n  tasks:\n    - name: installer le paquet\n      yum:\n        name: {{ web-package }}\n        state: latest"
    hint="Les noms de variables Ansible ont des règles strictes sur les caractères. Regardez la section vars: — concentrez-vous sur les noms eux-mêmes, pas sur les valeurs."
    instructions="[
                  {
                    \"instruction\": \"Les noms de variables ne peuvent contenir que des <span class=\\\"bold-green-text\\\">lettres, chiffres et tirets bas</span>. Les traits d'union (-) ne sont pas autorisés.\",
                    \"command\": \"# Correction : remplacer les traits d'union par des tirets bas\\nvars:\\n  web_package: httpd\\n  web_service: httpd\"
                  },
                  {
                    \"instruction\": \"Après correction des noms, ajoutez aussi des guillemets doubles autour de la référence car la valeur commence par {{ }}.\",
                    \"command\": \"        name: \\\"{{ web_package }}\\\"\"
                  }
                ]"
    answer_a="La valeur httpd doit être entourée de guillemets doubles"
    answer_b="La cible hosts: all est trop large et devrait nommer un groupe"
    answer_c="Les noms de variables web-package et web-service contiennent des traits d'union qui ne sont pas autorisés"  # Correct answer
    answer_d="Le module yum est obsolète, apt devrait être utilisé à la place"
    ;;
  *)
    question="What is wrong with the variable definition in this playbook?\n\n---\n- name: configure web server\n  hosts: all\n  vars:\n    web-package: httpd\n    web-service: httpd\n  tasks:\n    - name: install package\n      yum:\n        name: {{ web-package }}\n        state: latest"
    hint="Ansible variable names have strict character rules. Look at the vars: section — focus on the names themselves, not the values."
    instructions="[
                  {
                    \"instruction\": \"Variable names can contain only <span class=\\\"bold-green-text\\\">letters, numbers, and underscores</span>. Hyphens (-) are not allowed.\",
                    \"command\": \"# Fix: replace hyphens with underscores\\nvars:\\n  web_package: httpd\\n  web_service: httpd\"
                  },
                  {
                    \"instruction\": \"After fixing the names, also add double quotes around the reference since the value starts with {{ }}.\",
                    \"command\": \"        name: \\\"{{ web_package }}\\\"\"
                  }
                ]"
    answer_a="The value httpd must be wrapped in double quotes"
    answer_b="The hosts: all target is too broad and should name a group"
    answer_c="The variable names web-package and web-service contain hyphens which are not allowed"  # Correct answer
    answer_d="The yum module is deprecated, apt should be used instead"
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
