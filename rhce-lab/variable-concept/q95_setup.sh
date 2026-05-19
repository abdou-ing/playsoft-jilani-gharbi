#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/create_user.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that creates a user named \`devops\` on all \`webservers\` hosts, then run it."
    hint="Use the user module with name: devops and state: present. You will need become: yes since creating users requires root privileges."
    inst1="Create the playbook using the user module:"
    cmd1='---
- name: create devops user
  hosts: webservers
  become: yes
  tasks:
    - name: add user devops
      user:
        name: devops
        state: present'
    inst2="Run the playbook and verify the user exists:"
    cmd2="ansible-playbook ~/create_user.yml
ansible webservers -m command -a 'id devops'"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui crée un utilisateur nommé \`devops\` sur tous les hôtes \`webservers\`, puis exécutez-le."
    hint="Utilisez le module user avec name: devops et state: present. Vous aurez besoin de become: yes car la création d'utilisateurs nécessite des privilèges root."
    inst1="Créez le playbook en utilisant le module user :"
    cmd1='---
- name: créer l utilisateur devops
  hosts: webservers
  become: yes
  tasks:
    - name: ajouter l utilisateur devops
      user:
        name: devops
        state: present'
    inst2="Exécutez le playbook et vérifiez que l'utilisateur existe :"
    cmd2="ansible-playbook ~/create_user.yml
ansible webservers -m command -a 'id devops'"
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
