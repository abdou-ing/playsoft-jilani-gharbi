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
    question="What is wrong with the following playbook?\n\n---\n- name: install a package\n  hosts: all\n  vars:\n    pkg_name: httpd\n  tasks:\n    - name: install package\n      yum:\n        name: {{ pkg_name }}\n        state: present"
    hint="YAML has strict rules about values that start with certain characters. Look carefully at line 9 — the name: value in the yum task."
    instructions="[
                  {
                    \"instruction\": \"YAML treats any value starting with <span class=\\\"bold-green-text\\\">{{</span> as a dictionary literal and raises a parse error.\",
                    \"command\": \"# Fix: wrap the variable reference in double quotes\\n        name: \\\"{{ pkg_name }}\\\"\"
                  },
                  {
                    \"instruction\": \"The same rule applies everywhere a value begins with a variable reference.\",
                    \"command\": \"# WRONG:\\nsrc: {{ my_file }}\\n\\n# CORRECT:\\nsrc: \\\"{{ my_file }}\\\"\"
                  }
                ]"
    answer_a="The state: present should be state: latest"
    answer_b="The variable reference {{ pkg_name }} is missing double quotes"  # Correct answer
    answer_c="The vars: section should be placed inside tasks:"
    answer_d="The yum module requires a become: yes directive"
    ;;
  "fr")
    question="Qu'est-ce qui ne va pas dans ce playbook ?\n\n---\n- name: installer un paquet\n  hosts: all\n  vars:\n    pkg_name: httpd\n  tasks:\n    - name: installer le paquet\n      yum:\n        name: {{ pkg_name }}\n        state: present"
    hint="YAML a des règles strictes concernant les valeurs qui commencent par certains caractères. Regardez attentivement la ligne 9 — la valeur name: dans la tâche yum."
    instructions="[
                  {
                    \"instruction\": \"YAML traite toute valeur commençant par <span class=\\\"bold-green-text\\\">{{</span> comme un dictionnaire littéral et lève une erreur d'analyse.\",
                    \"command\": \"# Correction : entourez la référence de variable de guillemets doubles\\n        name: \\\"{{ pkg_name }}\\\"\"
                  },
                  {
                    \"instruction\": \"La même règle s'applique partout où une valeur commence par une référence de variable.\",
                    \"command\": \"# INCORRECT :\\nsrc: {{ my_file }}\\n\\n# CORRECT :\\nsrc: \\\"{{ my_file }}\\\"\"
                  }
                ]"
    answer_a="Le state: present devrait être state: latest"
    answer_b="La référence de variable {{ pkg_name }} est privée de guillemets doubles"  # Correct answer
    answer_c="La section vars: devrait être placée dans tasks:"
    answer_d="Le module yum nécessite une directive become: yes"
    ;;
  *)
    question="What is wrong with the following playbook?\n\n---\n- name: install a package\n  hosts: all\n  vars:\n    pkg_name: httpd\n  tasks:\n    - name: install package\n      yum:\n        name: {{ pkg_name }}\n        state: present"
    hint="YAML has strict rules about values that start with certain characters. Look carefully at line 9 — the name: value in the yum task."
    instructions="[
                  {
                    \"instruction\": \"YAML treats any value starting with <span class=\\\"bold-green-text\\\">{{</span> as a dictionary literal and raises a parse error.\",
                    \"command\": \"# Fix: wrap the variable reference in double quotes\\n        name: \\\"{{ pkg_name }}\\\"\"
                  },
                  {
                    \"instruction\": \"The same rule applies everywhere a value begins with a variable reference.\",
                    \"command\": \"# WRONG:\\nsrc: {{ my_file }}\\n\\n# CORRECT:\\nsrc: \\\"{{ my_file }}\\\"\"
                  }
                ]"
    answer_a="The state: present should be state: latest"
    answer_b="The variable reference {{ pkg_name }} is missing double quotes"  # Correct answer
    answer_c="The vars: section should be placed inside tasks:"
    answer_d="The yum module requires a become: yes directive"
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
