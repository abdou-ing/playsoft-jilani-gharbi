#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"

pb_path="/home/ansible_user/workspace/onboard_john.yml"

# Clean state: remove john from webservers so the task starts fresh
ansible webservers -i "$inventory" -m user -a "name=john state=absent remove=yes" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: onboard john to webservers
  hosts: webservers
  become: yes
  tasks:
    - name: create user john
      ansible.builtin.user:
        name: john
        create_home: yes
        shell: /bin/bash
        state: present
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'id john' --become
\`\`\`"

case "$lang" in
  en)
    question="A new junior developer, John, is joining the team. Write a playbook at \`$pb_path\` that creates the user \`john\` with a **home directory** and \`/bin/bash\` as his **login shell** on all \`webservers\`. Run it."
    hint="Use the ansible.builtin.user module with: name: john, create_home: yes, shell: /bin/bash, state: present. Target hosts: webservers. You need become: yes to manage users. Verify with: ansible webservers -m command -a 'id john' --become"
    inst1="Write the playbook at \`$pb_path\` using the \`user\` module — this is the idempotent way to create system users with Ansible:"
    inst2="Run the playbook at \`$pb_path\` and verify john exists on all webservers:"
    ;;
  fr)
    question="L'histoire : 'Provisionnement de l'équipe dev via Ansible'. Un nouveau développeur junior, John, rejoint l'équipe. Écrivez un playbook à \`$pb_path\` qui crée l'utilisateur \`john\` avec un **répertoire home** et \`/bin/bash\` comme **shell de connexion** sur tous les \`webservers\`. Exécutez-le."
    hint="Utilisez le module ansible.builtin.user avec : name: john, create_home: yes, shell: /bin/bash, state: present. Ciblez hosts: webservers. Vous avez besoin de become: yes pour gérer les utilisateurs. Vérifiez avec : ansible webservers -m command -a 'id john' --become"
    inst1="Écrivez le playbook à \`$pb_path\` avec le module \`user\` — c'est la méthode idempotente pour créer des utilisateurs système avec Ansible :"
    inst2="Exécutez le playbook à \`$pb_path\` et vérifiez que john existe sur tous les webservers :"
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
    "tags": "ansible,user,playbook,become,rhce"
  }'
