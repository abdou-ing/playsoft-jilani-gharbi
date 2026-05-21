#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/create_file.yml"
dest_file="/tmp/hello.txt"
content="Hello from Ansible"

cmd1='```yaml
---
- name: create hello file
  hosts: webservers
  tasks:
    - name: write hello.txt
      copy:
        content: "Hello from Ansible"
        dest: /tmp/hello.txt
```'
cmd2="ansible-playbook /home/ansible_user/workspace/create_file.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that creates the file \`$dest_file\` with the content \`$content\` on all \`webservers\` hosts, then run it."
    hint="Use the copy module with content: to write a string directly to a file on the remote host — no src file needed on the control node."
    inst1="Create the playbook using the <span class=\"bold-green-text\">copy</span> module with <span class=\"bold-green-text\">content:</span> to write a string directly to the remote file — no local src file needed:"
    inst2="Run the playbook to create the file on all <span class=\"bold-green-text\">webservers</span> hosts:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui crée le fichier \`$dest_file\` avec le contenu \`$content\` sur tous les hôtes \`webservers\`, puis exécutez-le."
    hint="Utilisez le module copy avec content: pour écrire une chaîne directement dans un fichier sur l'hôte distant — aucun fichier src n'est nécessaire sur le nœud de contrôle."
    inst1="Créez le playbook avec le module <span class=\"bold-green-text\">copy</span> et <span class=\"bold-green-text\">content:</span> pour écrire une chaîne directement sur le fichier distant — aucun fichier src local n'est nécessaire :"
    inst2="Exécutez le playbook pour créer le fichier sur tous les hôtes <span class=\"bold-green-text\">webservers</span> :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n --arg inst1 "$inst1" --arg cmd1 "$cmd1" --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --argjson instructions "$instructions" \
  '{
    "question": $question,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "type": "button",
    "hint": $hint,
    "instructions": $instructions,
    "text": "Check",
    "tags": "ansible,copy,playbook,files"
  }'
