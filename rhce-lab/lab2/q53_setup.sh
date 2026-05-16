#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`~/playbooks/users.yml\` that adds user \`alice\` (home: /home/alice, shell: /bin/bash) and modifies user \`bob\` (uid: 2006, home: /home/bob, shell: /bin/sh) on all managed hosts."
    hint="Use the \`user\` module. Set \`state: present\` for both tasks. Run with \`ansible-playbook playbooks/users.yml\` from your home directory."
    inst1="Create the playbook at ~/playbooks/users.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`~/playbooks/users.yml\` qui ajoute l'utilisateur \`alice\` (home: /home/alice, shell: /bin/bash) et modifie l'utilisateur \`bob\` (uid: 2006, home: /home/bob, shell: /bin/sh) sur toutes les machines hôtes."
    hint="Utilisez le module \`user\`. Définissez \`state: present\` pour les deux tâches. Exécutez avec \`ansible-playbook playbooks/users.yml\` depuis votre répertoire home."
    inst1="Créez le playbook dans ~/playbooks/users.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Manage users alice and bob
  hosts: all
  become: true
  tasks:
    - name: Add user alice
      user:
        name: alice
        home: /home/alice
        shell: /bin/bash
        state: present
    - name: Modify user bob
      user:
        name: bob
        uid: 2006
        home: /home/bob
        shell: /bin/sh
        state: present
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/users.yml
ansible-playbook playbooks/users.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,user"}'
