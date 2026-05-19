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
    question="What does the 'become: yes' directive do when added to a task or play in a playbook?"
    hint="Think about what account runs the task on the remote host. The remote_user connects first — what does become: yes change?"
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">become: yes</span> tells Ansible to escalate privileges using sudo before running that task, so it executes as root (or the become_user).\",
                    \"command\": \"- name: install httpd\\n  yum:\\n    name: httpd\\n    state: present\\n  become: yes\"
                  },
                  {
                    \"instruction\": \"You can apply become: at the play level (all tasks use sudo) or at the task level (only that task uses sudo).\",
                    \"command\": \"# Play level — every task runs as root:\\n- name: configure server\\n  hosts: all\\n  become: yes\\n  tasks: ...\\n\\n# Task level — only this task runs as root:\\n  tasks:\\n    - name: restart httpd\\n      service:\\n        name: httpd\\n        state: restarted\\n      become: yes\"
                  }
                ]"
    answer_a="Switches to a different target host mid-play"
    answer_b="Enables verbose output for the task"
    answer_c="Skips the task if it has already run"
    answer_d="Runs the task with privilege escalation (sudo)"  # Correct answer
    ;;
  "fr")
    question="Que fait la directive 'become: yes' lorsqu'elle est ajoutée à une tâche ou un play dans un playbook ?"
    hint="Pensez à quel compte exécute la tâche sur l'hôte distant. Le remote_user se connecte en premier — que change become: yes ?"
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">become: yes</span> indique à Ansible d'escalader les privilèges via sudo avant d'exécuter cette tâche, elle s'exécute donc en root (ou en become_user).\",
                    \"command\": \"- name: installer httpd\\n  yum:\\n    name: httpd\\n    state: present\\n  become: yes\"
                  },
                  {
                    \"instruction\": \"Vous pouvez appliquer become: au niveau du play (toutes les tâches utilisent sudo) ou au niveau de la tâche (uniquement cette tâche utilise sudo).\",
                    \"command\": \"# Niveau play — chaque tâche s'exécute en root :\\n- name: configurer le serveur\\n  hosts: all\\n  become: yes\\n  tasks: ...\\n\\n# Niveau tâche — seulement cette tâche s'exécute en root :\\n  tasks:\\n    - name: redémarrer httpd\\n      service:\\n        name: httpd\\n        state: restarted\\n      become: yes\"
                  }
                ]"
    answer_a="Bascule vers un hôte cible différent en cours de play"
    answer_b="Active la sortie verbeuse pour la tâche"
    answer_c="Ignore la tâche si elle a déjà été exécutée"
    answer_d="Exécute la tâche avec une escalade de privilèges (sudo)"  # Correct answer
    ;;
  *)
    question="What does the 'become: yes' directive do when added to a task or play in a playbook?"
    hint="Think about what account runs the task on the remote host. The remote_user connects first — what does become: yes change?"
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">become: yes</span> tells Ansible to escalate privileges using sudo before running that task, so it executes as root (or the become_user).\",
                    \"command\": \"- name: install httpd\\n  yum:\\n    name: httpd\\n    state: present\\n  become: yes\"
                  },
                  {
                    \"instruction\": \"You can apply become: at the play level (all tasks use sudo) or at the task level (only that task uses sudo).\",
                    \"command\": \"# Play level — every task runs as root:\\n- name: configure server\\n  hosts: all\\n  become: yes\\n  tasks: ...\\n\\n# Task level — only this task runs as root:\\n  tasks:\\n    - name: restart httpd\\n      service:\\n        name: httpd\\n        state: restarted\\n      become: yes\"
                  }
                ]"
    answer_a="Switches to a different target host mid-play"
    answer_b="Enables verbose output for the task"
    answer_c="Skips the task if it has already run"
    answer_d="Runs the task with privilege escalation (sudo)"  # Correct answer
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
