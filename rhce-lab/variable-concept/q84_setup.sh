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
    question="In a playbook, what does the 'hosts:' keyword define?"
    hint="Look at the top of any playbook. The hosts: line appears just after the play name and controls where the tasks are executed."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">hosts:</span> defines the target group or host pattern that the play runs against. It maps to entries in your inventory file.\",
                    \"command\": \"- name: configure web servers\\n  hosts: webservers\\n  tasks:\\n    - name: install nginx\\n      yum:\\n        name: nginx\\n        state: present\"
                  },
                  {
                    \"instruction\": \"You can use a group name, a single hostname, a pattern, or 'all' to target every host in the inventory.\",
                    \"command\": \"hosts: all          # every host\\nhosts: webservers   # a specific group\\nhosts: web01        # a single host\\nhosts: web*         # pattern matching\"
                  }
                ]"
    answer_a="The user running the playbook"
    answer_b="The list of variables for the play"
    answer_c="The control node name"
    answer_d="The target group or hosts the play runs against"  # Correct answer
    ;;
  "fr")
    question="Dans un playbook, que définit le mot-clé 'hosts:' ?"
    hint="Regardez le haut de n'importe quel playbook. La ligne hosts: apparaît juste après le nom du play et contrôle où les tâches sont exécutées."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">hosts:</span> définit le groupe cible ou le modèle d'hôtes sur lequel le play s'exécute. Il correspond aux entrées de votre fichier d'inventaire.\",
                    \"command\": \"- name: configurer les serveurs web\\n  hosts: webservers\\n  tasks:\\n    - name: installer nginx\\n      yum:\\n        name: nginx\\n        state: present\"
                  },
                  {
                    \"instruction\": \"Vous pouvez utiliser un nom de groupe, un nom d'hôte unique, un modèle ou 'all' pour cibler chaque hôte de l'inventaire.\",
                    \"command\": \"hosts: all          # chaque hôte\\nhosts: webservers   # un groupe spécifique\\nhosts: web01        # un hôte unique\\nhosts: web*         # correspondance de modèle\"
                  }
                ]"
    answer_a="L'utilisateur qui exécute le playbook"
    answer_b="La liste des variables du play"
    answer_c="Le nom du nœud de contrôle"
    answer_d="Le groupe cible ou les hôtes sur lesquels le play s'exécute"  # Correct answer
    ;;
  *)
    question="In a playbook, what does the 'hosts:' keyword define?"
    hint="Look at the top of any playbook. The hosts: line appears just after the play name and controls where the tasks are executed."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">hosts:</span> defines the target group or host pattern that the play runs against. It maps to entries in your inventory file.\",
                    \"command\": \"- name: configure web servers\\n  hosts: webservers\\n  tasks:\\n    - name: install nginx\\n      yum:\\n        name: nginx\\n        state: present\"
                  },
                  {
                    \"instruction\": \"You can use a group name, a single hostname, a pattern, or 'all' to target every host in the inventory.\",
                    \"command\": \"hosts: all          # every host\\nhosts: webservers   # a specific group\\nhosts: web01        # a single host\\nhosts: web*         # pattern matching\"
                  }
                ]"
    answer_a="The user running the playbook"
    answer_b="The list of variables for the play"
    answer_c="The control node name"
    answer_d="The target group or hosts the play runs against"  # Correct answer
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
