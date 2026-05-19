#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/install_pkg.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that installs the package defined by the \`pkg_name\` group variable on all \`webservers\` hosts, then run it."
    hint="Use the yum or apt module with name: '{{ pkg_name }}'. The variable pkg_name must already be set in your inventory (e.g. pkg_name=nginx under [webservers:vars])."
    inst1="Create the playbook using the pkg_name variable:"
    cmd1='---
- name: install package from variable
  hosts: webservers
  become: yes
  tasks:
    - name: install pkg_name
      package:
        name: "{{ pkg_name }}"
        state: present'
    inst2="Run the playbook:"
    cmd2="ansible-playbook ~/install_pkg.yml"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui installe le paquet défini par la variable de groupe \`pkg_name\` sur tous les hôtes \`webservers\`, puis exécutez-le."
    hint="Utilisez le module yum ou apt avec name: '{{ pkg_name }}'. La variable pkg_name doit déjà être définie dans votre inventaire (ex. pkg_name=nginx sous [webservers:vars])."
    inst1="Créez le playbook en utilisant la variable pkg_name :"
    cmd1='---
- name: installer le paquet depuis la variable
  hosts: webservers
  become: yes
  tasks:
    - name: installer pkg_name
      package:
        name: "{{ pkg_name }}"
        state: present'
    inst2="Exécutez le playbook :"
    cmd2="ansible-playbook ~/install_pkg.yml"
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
    "tags": "ansible,variables,package,playbook"
  }'
