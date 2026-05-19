#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/motd.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that creates the file \`/etc/motd\` with the content \`Managed by Ansible\` on ALL hosts, then run it."
    hint="Use the copy module with content: and dest: /etc/motd. You will need become: yes since /etc/motd is owned by root. Target hosts: all."
    inst1="Create the playbook to set the message of the day on all hosts:"
    cmd1='---
- name: set motd on all hosts
  hosts: all
  become: yes
  tasks:
    - name: write /etc/motd
      copy:
        content: "Managed by Ansible"
        dest: /etc/motd'
    inst2="Run the playbook and verify the file:"
    cmd2="ansible-playbook ~/motd.yml
ansible all -m command -a 'cat /etc/motd'"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui crée le fichier \`/etc/motd\` avec le contenu \`Managed by Ansible\` sur TOUS les hôtes, puis exécutez-le."
    hint="Utilisez le module copy avec content: et dest: /etc/motd. Vous aurez besoin de become: yes car /etc/motd appartient à root. Ciblez hosts: all."
    inst1="Créez le playbook pour définir le message du jour sur tous les hôtes :"
    cmd1='---
- name: définir le motd sur tous les hôtes
  hosts: all
  become: yes
  tasks:
    - name: écrire /etc/motd
      copy:
        content: "Managed by Ansible"
        dest: /etc/motd'
    inst2="Exécutez le playbook et vérifiez le fichier :"
    cmd2="ansible-playbook ~/motd.yml
ansible all -m command -a 'cat /etc/motd'"
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
    "tags": "ansible,copy,motd,become,playbook"
  }'
