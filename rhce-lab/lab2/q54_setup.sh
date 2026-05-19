#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`/home/ansible_user/playbooks/remove_user.yml\` that removes the user \`charlie\` from all managed hosts."
    hint="Use the \`ansible.builtin.user\` module with \`state: absent\`. To also remove the home directory add \`remove: true\`."
    inst1="Create the playbook at /home/ansible_user/playbooks/remove_user.yml:"
    inst2="Check the playbook syntax:"
    inst3="Run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`/home/ansible_user/playbooks/remove_user.yml\` qui supprime l'utilisateur \`charlie\` de toutes les machines hôtes."
    hint="Utilisez le module \`ansible.builtin.user\` avec \`state: absent\`. Pour supprimer également le répertoire home, ajoutez \`remove: true\`."
    inst1="Créez le playbook dans /home/ansible_user/playbooks/remove_user.yml :"
    inst2="Vérifiez la syntaxe du playbook :"
    inst3="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

ansible web1 -m user -a "name=charlie state=present" -b >/dev/null 2>&1


cmd_playbook='```yaml
- name: Remove user charlie
  hosts: all
  become: true
  tasks:
    - name: Delete charlie
      ansible.builtin.user:
        name: charlie
        state: absent
        remove: true
```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/remove_user.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/remove_user.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,user"}'
