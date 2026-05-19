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
    question="What does setting 'become = true' in the [privilege_escalation] section of ansible.cfg do?"
    hint="Think about what happens after Ansible SSHs into a managed host. The remote_user connects first — what does become handle?"
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">become = true</span> tells Ansible to run tasks with escalated privileges (sudo) after connecting with remote_user.\",
                    \"command\": \"[privilege_escalation]\\nbecome = true\\nbecome_method = sudo\\nbecome_user = root\\nbecome_ask_pass = false\"
                  },
                  {
                    \"instruction\": \"You can verify this is working by running an ad-hoc command. If the output shows root, privilege escalation is active.\",
                    \"command\": \"ansible all -a 'id'\\n# Expected output when become is working:\\nnode1 | CHANGED | rc=0 >>\\nuid=0(root) gid=0(root) groups=0(root)\"
                  }
                ]"
    answer_a="Ansible connects directly as root using the root password"
    answer_b="Ansible skips authentication and bypasses SSH key checks"
    answer_c="Ansible escalates privileges to root via sudo after connecting as remote_user"  # Correct answer
    answer_d="Ansible stores the become password in the inventory file"
    ;;
  "fr")
    question="Que fait le paramètre 'become = true' dans la section [privilege_escalation] d'ansible.cfg ?"
    hint="Pensez à ce qui se passe après qu'Ansible s'est connecté via SSH à un hôte géré. Le remote_user se connecte en premier — que gère become ?"
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">become = true</span> indique à Ansible d'exécuter les tâches avec des privilèges élevés (sudo) après s'être connecté avec remote_user.\",
                    \"command\": \"[privilege_escalation]\\nbecome = true\\nbecome_method = sudo\\nbecome_user = root\\nbecome_ask_pass = false\"
                  },
                  {
                    \"instruction\": \"Vous pouvez vérifier que cela fonctionne en exécutant une commande ad-hoc. Si la sortie affiche root, l'escalade de privilèges est active.\",
                    \"command\": \"ansible all -a 'id'\\n# Sortie attendue quand become fonctionne :\\nnode1 | CHANGED | rc=0 >>\\nuid=0(root) gid=0(root) groups=0(root)\"
                  }
                ]"
    answer_a="Ansible se connecte directement en root en utilisant le mot de passe root"
    answer_b="Ansible ignore l'authentification et contourne les vérifications de clé SSH"
    answer_c="Ansible escalade les privilèges vers root via sudo après la connexion en tant que remote_user"  # Correct answer
    answer_d="Ansible stocke le mot de passe become dans le fichier d'inventaire"
    ;;
  *)
    question="What does setting 'become = true' in the [privilege_escalation] section of ansible.cfg do?"
    hint="Think about what happens after Ansible SSHs into a managed host. The remote_user connects first — what does become handle?"
    instructions="[
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">become = true</span> tells Ansible to run tasks with escalated privileges (sudo) after connecting with remote_user.\",
                    \"command\": \"[privilege_escalation]\\nbecome = true\\nbecome_method = sudo\\nbecome_user = root\\nbecome_ask_pass = false\"
                  },
                  {
                    \"instruction\": \"You can verify this is working by running an ad-hoc command. If the output shows root, privilege escalation is active.\",
                    \"command\": \"ansible all -a 'id'\\n# Expected output when become is working:\\nnode1 | CHANGED | rc=0 >>\\nuid=0(root) gid=0(root) groups=0(root)\"
                  }
                ]"
    answer_a="Ansible connects directly as root using the root password"
    answer_b="Ansible skips authentication and bypasses SSH key checks"
    answer_c="Ansible escalates privileges to root via sudo after connecting as remote_user"  # Correct answer
    answer_d="Ansible stores the become password in the inventory file"
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
