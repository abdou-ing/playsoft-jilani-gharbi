#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/dev_group.yml"

# Skip-q60 guard
if [ ! -f "$inventory" ]; then
  mkdir -p /home/ansible_user/workspace
  printf '[webservers]\nweb1\nweb2\n\n[dbservers]\nbd1\n\n[all:vars]\nansible_user=ansible_user\n' > "$inventory"
fi
for entry in "10.30.0.11 web1" "10.30.0.12 web2" "10.30.0.13 bd1"; do
  grep -qF "${entry%% *}" /etc/hosts 2>/dev/null || printf '%s\n' "$entry" | sudo tee -a /etc/hosts >/dev/null 2>&1 || true
done
if [ ! -f "/home/ansible_user/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -b 2048 -f /home/ansible_user/.ssh/id_rsa -N "" >/dev/null 2>&1
  for _h in web1 web2 bd1; do
    SSHPASS='Labby123' sshpass -e ssh-copy-id -o StrictHostKeyChecking=no \
      -i /home/ansible_user/.ssh/id_rsa.pub ansible_user@"$_h" >/dev/null 2>&1 || true
  done
fi

# Skip-q78 guard: ensure john exists on webservers
ansible webservers -i "$inventory" -m user \
  -a "name=john create_home=yes shell=/bin/bash state=present" \
  --become -o >/dev/null 2>&1 || true

# Clean state: remove developers group from webservers so the task is fresh
ansible webservers -i "$inventory" -m group \
  -a "name=developers state=absent" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: configure developers group on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: create the developers group
      ansible.builtin.group:
        name: developers
        state: present

    - name: add john to the developers group
      ansible.builtin.user:
        name: john
        groups: developers
        append: yes
```'
cmd2="ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'id john' --become"

case "$lang" in
  en)
    question="The development team uses a shared group called \`developers\`. Write a playbook at \`$pb_path\` that creates the \`developers\` group and adds \`john\` as a secondary member on all \`webservers\`. Run it."
    hint="Use two tasks: ansible.builtin.group (create group) and ansible.builtin.user (add to group with append: yes). The 'append: yes' flag is critical — without it, the user module replaces ALL existing group memberships."
    inst1="Write the playbook with two tasks — <span class=\"bold-green-text\">group</span> to create the group, then <span class=\"bold-green-text\">user</span> with <span class=\"bold-green-text\">append: yes</span> to add john:"
    inst2="Run the playbook and verify that john belongs to <span class=\"bold-green-text\">developers</span> on all webservers:"
    ;;
  fr)
    question="L'équipe de développement utilise un groupe partagé appelé \`developers\`. Écrivez un playbook à \`$pb_path\` qui crée le groupe \`developers\` et ajoute \`john\` comme membre secondaire sur tous les \`webservers\`. Exécutez-le."
    hint="Utilisez deux tâches : ansible.builtin.group (créer le groupe) et ansible.builtin.user (ajouter au groupe avec append: yes). Le flag 'append: yes' est critique — sans lui, le module user remplace TOUTES les appartenances aux groupes existantes."
    inst1="Écrivez le playbook avec deux tâches — <span class=\"bold-green-text\">group</span> pour créer le groupe, puis <span class=\"bold-green-text\">user</span> avec <span class=\"bold-green-text\">append: yes</span> pour ajouter john :"
    inst2="Exécutez le playbook et vérifiez que john appartient à <span class=\"bold-green-text\">developers</span> sur tous les webservers :"
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
    "tags": "ansible,group,user,append,rhce"
  }'
