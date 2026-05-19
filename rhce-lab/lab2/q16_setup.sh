#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="What is the purpose of the <span class=\\\"bold-green-text\\\">become</span> directive in Ansible?"
    hint="Think about how Ansible can execute tasks as a different user."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">become</span> directive is used to execute tasks with elevated privileges or as a different user.\",
                    \"command\": \"- name: Install Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  become: yes\\n  become_user: root\"
                  },
                  {
                    \"instruction\": \"It is commonly used to run tasks as the root user.\",
                    \"command\": \"ansible-playbook playbook.yml --become\"
                  }
                ]"
    answer_a="It specifies the inventory group for a task."
    answer_b="It allows tasks to run with elevated privileges or as a different user."  # Correct answer
    answer_c="It sets the tags for a specific task."
    answer_d="It defines the variable precedence for playbooks."
    ;;
  "fr")
    question="Quel est le but de la directive <span class=\\\"bold-green-text\\\">become</span> dans Ansible ?"
    hint="Réfléchissez à la manière dont Ansible peut exécuter des tâches en tant qu'un autre utilisateur."
    instructions="[
                  {
                    \"instruction\": \"La directive <span class=\\\"bold-green-text\\\">become</span> est utilisée pour exécuter des tâches avec des privilèges élevés ou en tant qu'un autre utilisateur.\",
                    \"command\": \"- name: Installer Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  become: yes\\n  become_user: root\"
                  },
                  {
                    \"instruction\": \"Elle est couramment utilisée pour exécuter des tâches en tant qu'utilisateur root.\",
                    \"command\": \"ansible-playbook playbook.yml --become\"
                  }
                ]"
    answer_a="Elle spécifie le groupe d'inventaire pour une tâche."
    answer_b="Elle permet d'exécuter des tâches avec des privilèges élevés ou en tant qu'un autre utilisateur."  # Correct answer
    answer_c="Elle définit les tags pour une tâche spécifique."
    answer_d="Elle définit la précédence des variables pour les playbooks."
    ;;
  "es")
    question="¿Cuál es el propósito de la directiva <span class=\\\"bold-green-text\\\">become</span> en Ansible?"
    hint="Piensa en cómo Ansible puede ejecutar tareas como un usuario diferente."
    instructions="[
                  {
                    \"instruction\": \"La directiva <span class=\\\"bold-green-text\\\">become</span> se utiliza para ejecutar tareas con privilegios elevados o como un usuario diferente.\",
                    \"command\": \"- name: Instalar Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  become: yes\\n  become_user: root\"
                  },
                  {
                    \"instruction\": \"Se usa comúnmente para ejecutar tareas como el usuario root.\",
                    \"command\": \"ansible-playbook playbook.yml --become\"
                  }
                ]"
    answer_a="Especifica el grupo de inventario para una tarea."
    answer_b="Permite ejecutar tareas con privilegios elevados o como un usuario diferente."  # Correct answer
    answer_c="Define las etiquetas para una tarea específica."
    answer_d="Define la precedencia de variables para los playbooks."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the <span class=\\\"bold-green-text\\\">become</span> directive in Ansible?"
    hint="Think about how Ansible can execute tasks as a different user."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">become</span> directive is used to execute tasks with elevated privileges or as a different user.\",
                    \"command\": \"- name: Install Apache\\n  apt:\\n    name: apache2\\n    state: present\\n  become: yes\\n  become_user: root\"
                  },
                  {
                    \"instruction\": \"It is commonly used to run tasks as the root user.\",
                    \"command\": \"ansible-playbook playbook.yml --become\"
                  }
                ]"
    answer_a="It specifies the inventory group for a task."
    answer_b="It allows tasks to run with elevated privileges or as a different user."  # Correct answer
    answer_c="It sets the tags for a specific task."
    answer_d="It defines the variable precedence for playbooks."
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

# Pretty print the JSON output (optional)
echo "$display" | jq .