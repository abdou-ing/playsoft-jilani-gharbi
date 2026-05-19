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
    question="What is the default location of the Ansible inventory file when no ansible.cfg is configured?"
    hint="Run 'ansible --version' and look at the config file line. Then look at what Ansible uses when no custom config points to an inventory."
    instructions="[
                  {
                    \"instruction\": \"When no ansible.cfg is present, Ansible falls back to <span class=\\\"bold-green-text\\\">/etc/ansible/hosts</span> as the default inventory file.\",
                    \"command\": \"# Verify the fallback:\\nansible --version | grep 'config file'\\n# If no config: Ansible reads /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"In real RHCE exams you always create a custom ansible.cfg with an inventory= setting — so the default path is rarely used in practice.\",
                    \"command\": \"# Custom inventory in ansible.cfg:\\n[defaults]\\ninventory = /home/admin/ansible/inventory\"
                  }
                ]"
    answer_a="/etc/ansible/inventory"
    answer_b="/var/ansible/hosts"
    answer_c="~/.ansible/hosts"
    answer_d="/etc/ansible/hosts"  # Correct answer
    ;;
  "fr")
    question="Quel est l'emplacement par défaut du fichier d'inventaire Ansible quand aucun ansible.cfg n'est configuré ?"
    hint="Exécutez 'ansible --version' et regardez la ligne du fichier de configuration. Ensuite regardez ce qu'Ansible utilise quand aucune configuration personnalisée ne pointe vers un inventaire."
    instructions="[
                  {
                    \"instruction\": \"Quand aucun ansible.cfg n'est présent, Ansible utilise par défaut <span class=\\\"bold-green-text\\\">/etc/ansible/hosts</span> comme fichier d'inventaire.\",
                    \"command\": \"# Vérifier le fallback :\\nansible --version | grep 'config file'\\n# Sans config : Ansible lit /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"Dans les vrais examens RHCE vous créez toujours un ansible.cfg personnalisé avec un paramètre inventory= — donc le chemin par défaut est rarement utilisé en pratique.\",
                    \"command\": \"# Inventaire personnalisé dans ansible.cfg :\\n[defaults]\\ninventory = /home/admin/ansible/inventory\"
                  }
                ]"
    answer_a="/etc/ansible/inventory"
    answer_b="/var/ansible/hosts"
    answer_c="~/.ansible/hosts"
    answer_d="/etc/ansible/hosts"  # Correct answer
    ;;
  *)
    question="What is the default location of the Ansible inventory file when no ansible.cfg is configured?"
    hint="Run 'ansible --version' and look at the config file line. Then look at what Ansible uses when no custom config points to an inventory."
    instructions="[
                  {
                    \"instruction\": \"When no ansible.cfg is present, Ansible falls back to <span class=\\\"bold-green-text\\\">/etc/ansible/hosts</span> as the default inventory file.\",
                    \"command\": \"# Verify the fallback:\\nansible --version | grep 'config file'\\n# If no config: Ansible reads /etc/ansible/hosts\"
                  },
                  {
                    \"instruction\": \"In real RHCE exams you always create a custom ansible.cfg with an inventory= setting — so the default path is rarely used in practice.\",
                    \"command\": \"# Custom inventory in ansible.cfg:\\n[defaults]\\ninventory = /home/admin/ansible/inventory\"
                  }
                ]"
    answer_a="/etc/ansible/inventory"
    answer_b="/var/ansible/hosts"
    answer_c="~/.ansible/hosts"
    answer_d="/etc/ansible/hosts"  # Correct answer
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
