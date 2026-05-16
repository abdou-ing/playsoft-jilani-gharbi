#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`~/playbooks/add_hosts.yml\` that adds the line \`10.0.0.1 myserver\` to \`/etc/hosts\` on all managed hosts."
    hint="Use the \`lineinfile\` module with the \`line\` parameter. It ensures the line is present without duplicating it."
    inst1="Create the playbook at ~/playbooks/add_hosts.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`~/playbooks/add_hosts.yml\` qui ajoute la ligne \`10.0.0.1 myserver\` au fichier \`/etc/hosts\` sur toutes les machines hôtes."
    hint="Utilisez le module \`lineinfile\` avec le paramètre \`line\`. Il garantit que la ligne est présente sans la dupliquer."
    inst1="Créez le playbook dans ~/playbooks/add_hosts.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Add entry to /etc/hosts
  hosts: all
  become: true
  tasks:
    - name: Add 10.0.0.1 myserver to /etc/hosts
      lineinfile:
        path: /etc/hosts
        line: "10.0.0.1 myserver"
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/add_hosts.yml
ansible-playbook playbooks/add_hosts.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,lineinfile"}'
