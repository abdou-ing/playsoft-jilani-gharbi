#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/loop_install.yml"
inventory_path="/home/ansible_user/workspace/inventory"

# Skip-foundation guard
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
- name: install packages using a loop
  hosts: webservers
  become: yes
  tasks:
    - name: install each package
      package:
        name: "{{ item }}"
        state: present
      loop:
        - curl
        - tree
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/loop_install.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that uses \`loop\` to install the packages \`curl\` and \`tree\` on \`webservers\`. Use the \`package\` module with \`{{ item }}\` as the package name, then run it."
    hint="Define 'loop:' at the same indentation level as the 'package:' module. Use '{{ item }}' as the package name. Don't forget 'become: yes' to install packages."
    inst1="Create the playbook — use <span class=\"bold-green-text\">loop:</span> with a list of packages and <span class=\"bold-green-text\">{{ item }}</span> as the package name:"
    inst2="Run the playbook to install both packages on webservers:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui utilise \`loop\` pour installer les paquets \`curl\` et \`tree\` sur \`webservers\`. Utilisez le module \`package\` avec \`{{ item }}\` comme nom de paquet, puis exécutez-le."
    hint="Définissez 'loop:' au même niveau d'indentation que le module 'package:'. Utilisez '{{ item }}' comme nom de paquet. N'oubliez pas 'become: yes' pour installer des paquets."
    inst1="Créez le playbook — utilisez <span class=\"bold-green-text\">loop:</span> avec une liste de paquets et <span class=\"bold-green-text\">{{ item }}</span> comme nom de paquet :"
    inst2="Exécutez le playbook pour installer les deux paquets sur webservers :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  '[
    {"instruction": $inst1, "command": $cmd1},
    {"instruction": $inst2, "command": $cmd2}
  ]')

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
    "tags": "ansible,loop,package,item,playbook"
  }'
