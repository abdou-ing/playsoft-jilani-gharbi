#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`/home/ansible_user/playbooks/create_backup.yml\` that creates the directory \`/backup\` on all managed hosts with permissions \`0755\`, owned by \`root\` user and \`root\` group."
    hint="Use the \`ansible.builtin.file\` module with \`state: directory\`, \`mode\`, \`owner\`, and \`group\` parameters."
    inst1="Create the playbook at /home/ansible_user/playbooks/create_backup.yml:"
    inst2="Check the playbook syntax:"
    inst3="Run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`/home/ansible_user/playbooks/create_backup.yml\` qui crée le répertoire \`/backup\` sur toutes les machines hôtes avec les permissions \`0755\`, appartenant à l'utilisateur \`root\` et au groupe \`root\`."
    hint="Utilisez le module \`ansible.builtin.file\` avec \`state: directory\` et les paramètres \`mode\`, \`owner\` et \`group\`."
    inst1="Créez le playbook dans /home/ansible_user/playbooks/create_backup.yml :"
    inst2="Vérifiez la syntaxe du playbook :"
    inst3="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Create /backup directory
  hosts: all
  become: true
  tasks:
    - name: Create /backup with correct permissions
      ansible.builtin.file:
        path: /backup
        state: directory
        mode: "0755"
        owner: root
        group: root
```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/create_backup.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/create_backup.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,file,directory"}'
