#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/magic_vars.yml\` that writes \`/root/inventory_info.txt\` on all managed hosts using Ansible magic variables. The file must contain:\n\nINVENTORY_NAME=\`inventory_hostname\`\nGROUPS=\`group_names | join(',')\`\n\nUse the \`lineinfile\` module for each line."
    hint="\`inventory_hostname\` is the name of the host as defined in the inventory file. \`group_names\` is a list of all groups the current host belongs to — use the Jinja2 \`join\` filter to convert it to a comma-separated string."
    inst1="Create the playbook at ~/playbooks/magic_vars.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/magic_vars.yml\` qui écrit \`/root/inventory_info.txt\` sur tous les hôtes gérés en utilisant les variables magiques d'Ansible. Le fichier doit contenir :\n\nINVENTORY_NAME=\`inventory_hostname\`\nGROUPS=\`group_names | join(',')\`\n\nUtilisez le module \`lineinfile\` pour chaque ligne."
    hint="\`inventory_hostname\` est le nom de l'hôte tel que défini dans le fichier d'inventaire. \`group_names\` est une liste de tous les groupes auxquels appartient l'hôte courant — utilisez le filtre Jinja2 \`join\` pour le convertir en chaîne séparée par des virgules."
    inst1="Créez le playbook dans ~/playbooks/magic_vars.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Use Ansible magic variables
  hosts: all
  become: true
  tasks:
    - name: Set INVENTORY_NAME line
      lineinfile:
        path: /root/inventory_info.txt
        regexp: "^INVENTORY_NAME="
        line: "INVENTORY_NAME={{ inventory_hostname }}"
        create: yes

    - name: Set GROUPS line
      lineinfile:
        path: /root/inventory_info.txt
        regexp: "^GROUPS="
        line: "GROUPS={{ group_names | join(',') }}"
        create: yes
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/magic_vars.yml
ansible-playbook playbooks/magic_vars.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,magic_variables,inventory_hostname,group_names,lineinfile"}'
