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
    question="Which command verifies BOTH that Ansible can reach all managed hosts AND that privilege escalation is working correctly?"
    hint="Run both commands on your control node. One checks connectivity only. The other runs as root and tells you exactly which user the task ran as — so you can confirm privilege escalation."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible all -a 'id'</span> runs the id command on every host. If the output shows root, become is working. If it shows the remote_user, become is not active.\",
                    \"command\": \"ansible all -a 'id'\\n# Good output (become working):\\nnode1 | CHANGED | rc=0 >>\\nuid=0(root) gid=0(root) groups=0(root)\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible all -m ping</span> only checks SSH connectivity — it does NOT verify privilege escalation.\",
                    \"command\": \"# ping only checks SSH connectivity:\\nansible all -m ping\\n\\n# id checks both connectivity AND privilege escalation:\\nansible all -a 'id'\"
                  }
                ]"
    answer_a="ansible all -m ping"
    answer_b="ansible all -m setup"
    answer_c="ansible-playbook --check site.yml"
    answer_d="ansible all -a 'id'"  # Correct answer
    ;;
  "fr")
    question="Quelle commande vérifie À LA FOIS qu'Ansible peut atteindre tous les hôtes gérés ET que l'escalade de privilèges fonctionne correctement ?"
    hint="Exécutez les deux commandes sur votre nœud de contrôle. L'une vérifie uniquement la connectivité. L'autre s'exécute en root et vous indique exactement quel utilisateur a exécuté la tâche — vous pouvez ainsi confirmer l'escalade de privilèges."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible all -a 'id'</span> exécute la commande id sur chaque hôte. Si la sortie affiche root, become fonctionne. Si elle affiche le remote_user, become n'est pas actif.\",
                    \"command\": \"ansible all -a 'id'\\n# Bonne sortie (become actif) :\\nnode1 | CHANGED | rc=0 >>\\nuid=0(root) gid=0(root) groups=0(root)\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible all -m ping</span> vérifie uniquement la connectivité SSH — il ne vérifie PAS l'escalade de privilèges.\",
                    \"command\": \"# ping vérifie uniquement la connectivité SSH :\\nansible all -m ping\\n\\n# id vérifie à la fois la connectivité ET l'escalade de privilèges :\\nansible all -a 'id'\"
                  }
                ]"
    answer_a="ansible all -m ping"
    answer_b="ansible all -m setup"
    answer_c="ansible-playbook --check site.yml"
    answer_d="ansible all -a 'id'"  # Correct answer
    ;;
  *)
    question="Which command verifies BOTH that Ansible can reach all managed hosts AND that privilege escalation is working correctly?"
    hint="Run both commands on your control node. One checks connectivity only. The other runs as root and tells you exactly which user the task ran as — so you can confirm privilege escalation."
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible all -a 'id'</span> runs the id command on every host. If the output shows root, become is working. If it shows the remote_user, become is not active.\",
                    \"command\": \"ansible all -a 'id'\\n# Good output (become working):\\nnode1 | CHANGED | rc=0 >>\\nuid=0(root) gid=0(root) groups=0(root)\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible all -m ping</span> only checks SSH connectivity — it does NOT verify privilege escalation.\",
                    \"command\": \"# ping only checks SSH connectivity:\\nansible all -m ping\\n\\n# id checks both connectivity AND privilege escalation:\\nansible all -a 'id'\"
                  }
                ]"
    answer_a="ansible all -m ping"
    answer_b="ansible all -m setup"
    answer_c="ansible-playbook --check site.yml"
    answer_d="ansible all -a 'id'"  # Correct answer
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
  "plateforme_required": "container",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
