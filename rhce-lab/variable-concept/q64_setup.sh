#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/when_demo.yml"
inventory_path="/home/ansible_user/workspace/inventory"

# Skip-q60 guard
if [ ! -f "$inventory_path" ]; then
  mkdir -p /home/ansible_user/workspace
  printf '[webservers]\nweb1\nweb2\n\n[dbservers]\nbd1\n\n[all:vars]\nansible_user=ansible_user\n' \
    > "$inventory_path"
fi
for entry in "10.30.0.11 web1" "10.30.0.12 web2" "10.30.0.13 bd1"; do
  grep -qF "${entry%% *}" /etc/hosts 2>/dev/null || \
    printf '%s\n' "$entry" | sudo tee -a /etc/hosts >/dev/null 2>&1 || true
done
if [ ! -f "/home/ansible_user/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -b 2048 -f /home/ansible_user/.ssh/id_rsa -N "" >/dev/null 2>&1
  for _h in web1 web2 bd1; do
    SSHPASS='Labby123' sshpass -e ssh-copy-id -o StrictHostKeyChecking=no \
      -i /home/ansible_user/.ssh/id_rsa.pub ansible_user@"$_h" >/dev/null 2>&1 || true
  done
fi

cmd1='```yaml
---
- name: conditional package install
  hosts: webservers
  become: yes
  tasks:
    - name: install tree on Debian systems
      package:
        name: tree
        state: present
      when: ansible_os_family == "Debian"
```'

cmd2="ansible-playbook -i $inventory_path $pb_path"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` targeting \`webservers\` that installs the \`tree\` package only when \`ansible_os_family == \"Debian\"\` using the \`when:\` directive. Use \`become: yes\` and run the playbook."
    hint="The when: directive accepts a Jinja2 expression without curly braces. ansible_os_family is a fact collected automatically by Ansible — no setup task needed. Use become: yes since package installation requires root."
    inst1="Create the playbook at <span class=\"bold-green-text\">$pb_path</span> with a <span class=\"bold-green-text\">when:</span> condition on the install task — note: no <span class=\"bold-green-text\">{{ }}</span> needed in when: expressions:"
    inst2="Run the playbook — <span class=\"bold-green-text\">tree</span> should be installed only on webservers where the OS family is Debian:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` ciblant \`webservers\` qui installe le paquet \`tree\` uniquement quand \`ansible_os_family == \"Debian\"\` en utilisant la directive \`when:\`. Utilisez \`become: yes\` et exécutez le playbook."
    hint="La directive when: accepte une expression Jinja2 sans accolades. ansible_os_family est un fait collecté automatiquement par Ansible — aucune tâche setup n'est nécessaire. Utilisez become: yes car l'installation de paquets requiert les droits root."
    inst1="Créez le playbook à <span class=\"bold-green-text\">$pb_path</span> avec une condition <span class=\"bold-green-text\">when:</span> sur la tâche d'installation — remarque : pas de <span class=\"bold-green-text\">{{ }}</span> nécessaire dans les expressions when: :"
    inst2="Exécutez le playbook — <span class=\"bold-green-text\">tree</span> doit être installé uniquement sur les webservers dont la famille OS est Debian :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
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
    "tags": "ansible,variables,when,conditional,playbook"
  }'
