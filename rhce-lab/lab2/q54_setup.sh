#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`~/playbooks/remove_user.yml\` that removes the user \`charlie\` from all managed hosts."
    hint="Use the \`user\` module with \`state: absent\`. To also remove the home directory add \`remove: true\`."
    inst1="Create the playbook at ~/playbooks/remove_user.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`~/playbooks/remove_user.yml\` qui supprime l'utilisateur \`charlie\` de toutes les machines hôtes."
    hint="Utilisez le module \`user\` avec \`state: absent\`. Pour supprimer également le répertoire home, ajoutez \`remove: true\`."
    inst1="Créez le playbook dans ~/playbooks/remove_user.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Remove user charlie
  hosts: all
  become: true
  tasks:
    - name: Delete charlie
      user:
        name: charlie
        state: absent
        remove: true
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/remove_user.yml
ansible-playbook playbooks/remove_user.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,user"}'
