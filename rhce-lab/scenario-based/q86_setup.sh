#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/hosts_entries.yml"

# Clean state: remove custom hosts entries from all managed hosts
for _entry in "10.30.0.11 web1" "10.30.0.12 web2" "10.30.0.13 bd1"; do
  ansible all -i "$inventory" -m lineinfile \
    -a "path=/etc/hosts line='$_entry' state=absent" \
    --become -o >/dev/null 2>&1 || true
done
rm -f "$pb_path"

cmd1='```yaml
---
- name: ensure /etc/hosts entries on all managed hosts
  hosts: all
  become: yes
  tasks:
    - name: add web1 entry
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "10.30.0.11 web1"
        state: present

    - name: add web2 entry
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "10.30.0.12 web2"
        state: present

    - name: add bd1 entry
      ansible.builtin.lineinfile:
        path: /etc/hosts
        line: "10.30.0.13 bd1"
        state: present
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible all -i $inventory -m command -a 'grep -E \"web1|web2|bd1\" /etc/hosts' --become
\`\`\`"

case "$lang" in
  en)
    question="All managed hosts need to **resolve each other by hostname**. Write a playbook at \`$pb_path\` that adds the following entries to \`/etc/hosts\` on \`all\` managed hosts: \`10.30.0.11 web1\`, \`10.30.0.12 web2\`, \`10.30.0.13 bd1\`. Use the \`lineinfile\` module with \`state: present\`."
    hint="Use ansible.builtin.lineinfile with path: /etc/hosts and line: for each entry. Set state: present — lineinfile will only add the line if it is not already there (idempotent). Target hosts: all to apply to webservers and dbservers. Verify: ansible all -m command -a 'grep -E \"web1|web2|bd1\" /etc/hosts' --become"
    inst1="Write the playbook at \`$pb_path\` — one \`lineinfile\` task per host entry:"
    inst2="Run the playbook and verify the /etc/hosts entries on all managed hosts:"
    ;;
  fr)
    question="Tous les hôtes gérés doivent **se résoudre mutuellement par nom d'hôte**. Écrivez un playbook à \`$pb_path\` qui ajoute les entrées suivantes à \`/etc/hosts\` sur \`all\` les hôtes gérés : \`10.30.0.11 web1\`, \`10.30.0.12 web2\`, \`10.30.0.13 bd1\`. Utilisez le module \`lineinfile\` avec \`state: present\`."
    hint="Utilisez ansible.builtin.lineinfile avec path: /etc/hosts et line: pour chaque entrée. Définissez state: present — lineinfile n'ajoutera la ligne que si elle n'est pas déjà présente (idempotent). Ciblez hosts: all pour appliquer aux webservers et dbservers. Vérifiez : ansible all -m command -a 'grep -E \"web1|web2|bd1\" /etc/hosts' --become"
    inst1="Écrivez le playbook à \`$pb_path\` — une tâche \`lineinfile\` par entrée d'hôte :"
    inst2="Exécutez le playbook et vérifiez les entrées /etc/hosts sur tous les hôtes gérés :"
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
    "tags": "ansible,lineinfile,hosts,dns,rhce"
  }'
