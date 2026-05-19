#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`/home/ansible_user/playbooks/users.yml\` that adds user \`alice\` (home: /home/alice, shell: /bin/bash) and modifies user \`bob\` (uid: 2006, home: /home/bob, shell: /bin/sh) on all managed hosts."
    hint="Use the \`ansible.builtin.user\` module. Set \`state: present\` for both tasks. Run with \`ansible-playbook playbooks/users.yml\` from your home directory."
    inst1="Create the playbook at /home/ansible_user/playbooks/users.yml:"
    inst2="Check the playbook syntax:"
    inst3="Run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`/home/ansible_user/playbooks/users.yml\` qui ajoute l'utilisateur \`alice\` (home: /home/alice, shell: /bin/bash) et modifie l'utilisateur \`bob\` (uid: 2006, home: /home/bob, shell: /bin/sh) sur toutes les machines hôtes."
    hint="Utilisez le module \`ansible.builtin.user\`. Définissez \`state: present\` pour les deux tâches. Exécutez avec \`ansible-playbook playbooks/users.yml\` depuis votre répertoire home."
    inst1="Créez le playbook dans /home/ansible_user/playbooks/users.yml :"
    inst2="Vérifiez la syntaxe du playbook :"
    inst3="Exécutez le playbook :"
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
      ansible.builtin.user:
        name: alice
        home: /home/alice
        shell: /bin/bash
        state: present
    - name: Modify user bob
      ansible.builtin.user:
        name: bob
        uid: 2006
        home: /home/bob
        shell: /bin/sh
        state: present
```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/users.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/users.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,user"}'
