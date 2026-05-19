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
    question="In a playbook, which keyword gives a task a human-readable description that appears in the output when the playbook runs?"
    hint="Look at any playbook task block. One keyword labels the task so you can read what it is doing in the terminal output without reading the module parameters."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">name:</span> keyword labels a task. It is optional but strongly recommended — it is printed during playbook execution.\",
                    \"command\": \"tasks:\\n  - name: install nginx package\\n    yum:\\n      name: nginx\\n      state: present\"
                  },
                  {
                    \"instruction\": \"Without a name, Ansible prints the raw module call, which is harder to read. Always use name: for every task.\",
                    \"command\": \"# Without name: (hard to read):\\nYAML action: yum name=nginx state=present\\n\\n# With name: (clear):\\nTASK [install nginx package]\"
                  }
                ]"
    answer_a="desc"
    answer_b="title"
    answer_c="label"
    answer_d="name"  # Correct answer
    ;;
  "fr")
    question="Dans un playbook, quel mot-clé donne à une tâche une description lisible par l'humain qui apparaît dans la sortie lors de l'exécution du playbook ?"
    hint="Regardez n'importe quel bloc de tâche dans un playbook. Un mot-clé étiquette la tâche pour que vous puissiez lire ce qu'elle fait dans la sortie terminal sans lire les paramètres du module."
    instructions="[
                  {
                    \"instruction\": \"Le mot-clé <span class=\\\"bold-green-text\\\">name:</span> étiquette une tâche. Il est optionnel mais fortement recommandé — il est affiché lors de l'exécution du playbook.\",
                    \"command\": \"tasks:\\n  - name: installer le paquet nginx\\n    yum:\\n      name: nginx\\n      state: present\"
                  },
                  {
                    \"instruction\": \"Sans name, Ansible affiche l'appel brut du module, plus difficile à lire. Utilisez toujours name: pour chaque tâche.\",
                    \"command\": \"# Sans name: (difficile à lire) :\\nYAML action: yum name=nginx state=present\\n\\n# Avec name: (clair) :\\nTASK [installer le paquet nginx]\"
                  }
                ]"
    answer_a="desc"
    answer_b="title"
    answer_c="label"
    answer_d="name"  # Correct answer
    ;;
  *)
    question="In a playbook, which keyword gives a task a human-readable description that appears in the output when the playbook runs?"
    hint="Look at any playbook task block. One keyword labels the task so you can read what it is doing in the terminal output without reading the module parameters."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">name:</span> keyword labels a task. It is optional but strongly recommended — it is printed during playbook execution.\",
                    \"command\": \"tasks:\\n  - name: install nginx package\\n    yum:\\n      name: nginx\\n      state: present\"
                  },
                  {
                    \"instruction\": \"Without a name, Ansible prints the raw module call, which is harder to read. Always use name: for every task.\",
                    \"command\": \"# Without name: (hard to read):\\nYAML action: yum name=nginx state=present\\n\\n# With name: (clear):\\nTASK [install nginx package]\"
                  }
                ]"
    answer_a="desc"
    answer_b="title"
    answer_c="label"
    answer_d="name"  # Correct answer
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
