#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/create_user.yml"

cmd1='```yaml
---
- name: create devops user
  hosts: webservers
  become: yes
  tasks:
    - name: add user devops
      user:
        name: devops
        state: present
```'
cmd2="ansible-playbook /home/ansible_user/workspace/create_user.yml
ansible webservers -m command -a 'id devops'"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that creates a user named \`devops\` on all \`webservers\` hosts, then run it."
    hint="Use the user module with name: devops and state: present. You will need become: yes since creating users requires root privileges."
    inst1="Create the playbook using the <span class=\"bold-green-text\">user</span> module with <span class=\"bold-green-text\">name: devops</span> and <span class=\"bold-green-text\">state: present</span> — requires <span class=\"bold-green-text\">become: yes</span>:"
    inst2="Run the playbook and verify the <span class=\"bold-green-text\">devops</span> user was created on all webservers:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui crée un utilisateur nommé \`devops\` sur tous les hôtes \`webservers\`, puis exécutez-le."
    hint="Utilisez le module user avec name: devops et state: present. Vous aurez besoin de become: yes car la création d'utilisateurs nécessite des privilèges root."
    inst1="Créez le playbook avec le module <span class=\"bold-green-text\">user</span> avec <span class=\"bold-green-text\">name: devops</span> et <span class=\"bold-green-text\">state: present</span> — nécessite <span class=\"bold-green-text\">become: yes</span> :"
    inst2="Exécutez le playbook et vérifiez que l'utilisateur <span class=\"bold-green-text\">devops</span> a été créé sur tous les webservers :"
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
    "tags": "ansible,user,playbook,become"
  }'
