#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/loop_vars.yml"
vars_path="/home/ansible_user/workspace/vars/pkglist.yml"
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

mkdir -p /home/ansible_user/workspace/vars

cmd1='```yaml
# ~/workspace/vars/pkglist.yml
packages:
  - name: nmap
    state: present
  - name: wget
    state: present
  - name: tree
    state: latest
```'

cmd2='```yaml
---
- name: install packages from vars file
  hosts: webservers
  become: yes
  vars_files: vars/pkglist.yml
  tasks:
    - name: manage each package
      package:
        name: "{{ item.name }}"
        state: "{{ item.state }}"
      loop: "{{ packages }}"
```'

cmd3="ansible-playbook -i ~/workspace/inventory ~/workspace/loop_vars.yml"

case "$lang" in
  en)
    question="Create a variables file at \`$vars_path\` containing a list of packages with \`name\` and \`state\` fields, then write a playbook at \`$pb_path\` that loads the file with \`vars_files\` and installs each package using \`loop\` with \`item.name\` and \`item.state\`. Run the playbook on webservers."
    hint="In the vars file, define 'packages:' as a list where each entry has 'name:' and 'state:'. In the playbook use vars_files: vars/pkglist.yml and loop: \"{{ packages }}\" — then reference item.name and item.state."
    inst1="Create the variables file at <span class=\"bold-green-text\">~/workspace/vars/pkglist.yml</span> with a list of packages, each having <span class=\"bold-green-text\">name:</span> and <span class=\"bold-green-text\">state:</span>:"
    inst2="Write the playbook at <span class=\"bold-green-text\">$pb_path</span> — load the file with <span class=\"bold-green-text\">vars_files:</span> and loop using <span class=\"bold-green-text\">item.name</span> and <span class=\"bold-green-text\">item.state</span>:"
    inst3="Run the playbook on webservers:"
    ;;
  fr)
    question="Créez un fichier de variables à \`$vars_path\` contenant une liste de paquets avec les champs \`name\` et \`state\`, puis écrivez un playbook à \`$pb_path\` qui charge le fichier avec \`vars_files\` et installe chaque paquet via \`loop\` avec \`item.name\` et \`item.state\`. Exécutez le playbook sur webservers."
    hint="Dans le fichier vars, définissez 'packages:' comme liste où chaque entrée a 'name:' et 'state:'. Dans le playbook, utilisez vars_files: vars/pkglist.yml et loop: \"{{ packages }}\" — puis référencez item.name et item.state."
    inst1="Créez le fichier de variables à <span class=\"bold-green-text\">~/workspace/vars/pkglist.yml</span> avec une liste de paquets ayant chacun <span class=\"bold-green-text\">name:</span> et <span class=\"bold-green-text\">state:</span> :"
    inst2="Écrivez le playbook à <span class=\"bold-green-text\">$pb_path</span> — chargez le fichier avec <span class=\"bold-green-text\">vars_files:</span> et bouclez avec <span class=\"bold-green-text\">item.name</span> et <span class=\"bold-green-text\">item.state</span> :"
    inst3="Exécutez le playbook sur webservers :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd3" \
  '[
    {"instruction": $inst1, "command": $cmd1},
    {"instruction": $inst2, "command": $cmd2},
    {"instruction": $inst3, "command": $cmd3}
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
    "tags": "ansible,loop,vars_files,multivalued,package,playbook"
  }'
