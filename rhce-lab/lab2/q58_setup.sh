#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`~/playbooks/create_backup.yml\` that creates the directory \`/backup\` on all managed hosts with permissions \`0755\`, owned by \`root\` user and \`root\` group."
    hint="Use the \`file\` module with \`state: directory\`, \`mode\`, \`owner\`, and \`group\` parameters."
    inst1="Create the playbook at ~/playbooks/create_backup.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`~/playbooks/create_backup.yml\` qui crée le répertoire \`/backup\` sur toutes les machines hôtes avec les permissions \`0755\`, appartenant à l'utilisateur \`root\` et au groupe \`root\`."
    hint="Utilisez le module \`file\` avec \`state: directory\` et les paramètres \`mode\`, \`owner\` et \`group\`."
    inst1="Créez le playbook dans ~/playbooks/create_backup.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
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
      file:
        path: /backup
        state: directory
        mode: "0755"
        owner: root
        group: root
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/create_backup.yml
ansible-playbook playbooks/create_backup.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,file,directory"}'
