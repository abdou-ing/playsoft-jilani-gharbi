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
    question="Which ansible.cfg setting in the [defaults] section specifies the SSH username Ansible uses to connect to managed hosts?"
    hint="Look at a typical ansible.cfg [defaults] block. There is one setting that sets the Linux account Ansible will SSH into on the remote host."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">remote_user</span> sets the SSH login account used on every managed host unless overridden in the inventory.\",
                    \"command\": \"[defaults]\\nremote_user = admin\"
                  },
                  {
                    \"instruction\": \"Do not confuse remote_user (SSH login account) with become_user (the account privileges are escalated TO after login).\",
                    \"command\": \"[defaults]\\nremote_user = admin\\n\\n[privilege_escalation]\\nbecome = true\\nbecome_user = root\"
                  }
                ]"
    answer_a="ansible_user"
    answer_b="ssh_user"
    answer_c="become_user"
    answer_d="remote_user"  # Correct answer
    ;;
  "fr")
    question="Quel paramètre d'ansible.cfg dans la section [defaults] spécifie le nom d'utilisateur SSH qu'Ansible utilise pour se connecter aux hôtes gérés ?"
    hint="Regardez un bloc [defaults] typique d'ansible.cfg. Il y a un paramètre qui définit le compte Linux dans lequel Ansible se connecte via SSH sur l'hôte distant."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">remote_user</span> définit le compte de connexion SSH utilisé sur chaque hôte géré, sauf s'il est remplacé dans l'inventaire.\",
                    \"command\": \"[defaults]\\nremote_user = admin\"
                  },
                  {
                    \"instruction\": \"Ne pas confondre remote_user (compte de connexion SSH) avec become_user (le compte vers lequel les privilèges sont escaladés APRÈS la connexion).\",
                    \"command\": \"[defaults]\\nremote_user = admin\\n\\n[privilege_escalation]\\nbecome = true\\nbecome_user = root\"
                  }
                ]"
    answer_a="ansible_user"
    answer_b="ssh_user"
    answer_c="become_user"
    answer_d="remote_user"  # Correct answer
    ;;
  *)
    question="Which ansible.cfg setting in the [defaults] section specifies the SSH username Ansible uses to connect to managed hosts?"
    hint="Look at a typical ansible.cfg [defaults] block. There is one setting that sets the Linux account Ansible will SSH into on the remote host."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">remote_user</span> sets the SSH login account used on every managed host unless overridden in the inventory.\",
                    \"command\": \"[defaults]\\nremote_user = admin\"
                  },
                  {
                    \"instruction\": \"Do not confuse remote_user (SSH login account) with become_user (the account privileges are escalated TO after login).\",
                    \"command\": \"[defaults]\\nremote_user = admin\\n\\n[privilege_escalation]\\nbecome = true\\nbecome_user = root\"
                  }
                ]"
    answer_a="ansible_user"
    answer_b="ssh_user"
    answer_c="become_user"
    answer_d="remote_user"  # Correct answer
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
