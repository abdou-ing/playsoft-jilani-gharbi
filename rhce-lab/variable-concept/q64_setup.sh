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
    question="Where must custom fact files be stored on managed hosts for Ansible to discover them automatically?"
    hint="Ansible looks for a specific directory under /etc on managed hosts. The files must have a .fact extension and be in INI or JSON format."
    instructions="[
                  {
                    \"instruction\": \"Create the <span class=\\\"bold-green-text\\\">/etc/ansible/facts.d</span> directory and deploy a .fact file to it using a playbook.\",
                    \"command\": \"- name: create facts directory\\n  file:\\n    state: directory\\n    path: /etc/ansible/facts.d\\n    recurse: yes\\n\\n- name: deploy custom fact file\\n  copy:\\n    src: custom.fact\\n    dest: /etc/ansible/facts.d/\"
                  },
                  {
                    \"instruction\": \"Verify that custom facts are discovered by running the setup module with a filter.\",
                    \"command\": \"ansible all -m setup -a \\\"filter=ansible_local\\\"\"
                  }
                ]"
    answer_a="/etc/ansible/facts"
    answer_b="/etc/ansible/facts.d"  # Correct answer
    answer_c="/var/ansible/facts.d"
    answer_d="~/.ansible/facts.d"
    ;;
  "fr")
    question="Où les fichiers de faits personnalisés doivent-ils être stockés sur les hôtes gérés pour qu'Ansible les découvre automatiquement ?"
    hint="Ansible cherche dans un répertoire spécifique sous /etc sur les hôtes gérés. Les fichiers doivent avoir l'extension .fact et être au format INI ou JSON."
    instructions="[
                  {
                    \"instruction\": \"Créez le répertoire <span class=\\\"bold-green-text\\\">/etc/ansible/facts.d</span> et déployez un fichier .fact avec un playbook.\",
                    \"command\": \"- name: créer le répertoire des faits\\n  file:\\n    state: directory\\n    path: /etc/ansible/facts.d\\n    recurse: yes\\n\\n- name: déployer le fichier de fait personnalisé\\n  copy:\\n    src: custom.fact\\n    dest: /etc/ansible/facts.d/\"
                  },
                  {
                    \"instruction\": \"Vérifiez que les faits personnalisés sont découverts avec le module setup et un filtre.\",
                    \"command\": \"ansible all -m setup -a \\\"filter=ansible_local\\\"\"
                  }
                ]"
    answer_a="/etc/ansible/facts"
    answer_b="/etc/ansible/facts.d"  # Correct answer
    answer_c="/var/ansible/facts.d"
    answer_d="~/.ansible/facts.d"
    ;;
  *)
    question="Where must custom fact files be stored on managed hosts for Ansible to discover them automatically?"
    hint="Ansible looks for a specific directory under /etc on managed hosts. The files must have a .fact extension and be in INI or JSON format."
    instructions="[
                  {
                    \"instruction\": \"Create the <span class=\\\"bold-green-text\\\">/etc/ansible/facts.d</span> directory and deploy a .fact file to it using a playbook.\",
                    \"command\": \"- name: create facts directory\\n  file:\\n    state: directory\\n    path: /etc/ansible/facts.d\\n    recurse: yes\\n\\n- name: deploy custom fact file\\n  copy:\\n    src: custom.fact\\n    dest: /etc/ansible/facts.d/\"
                  },
                  {
                    \"instruction\": \"Verify that custom facts are discovered by running the setup module with a filter.\",
                    \"command\": \"ansible all -m setup -a \\\"filter=ansible_local\\\"\"
                  }
                ]"
    answer_a="/etc/ansible/facts"
    answer_b="/etc/ansible/facts.d"  # Correct answer
    answer_c="/var/ansible/facts.d"
    answer_d="~/.ansible/facts.d"
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
