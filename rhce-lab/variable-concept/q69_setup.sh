#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/install_pkg.yml"

cmd1='```yaml
---
- name: install package from variable
  hosts: webservers
  become: yes
  tasks:
    - name: install pkg_name
      package:
        name: "{{ pkg_name }}"
        state: present
```'
cmd2="ansible-playbook /home/ansible_user/workspace/install_pkg.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that installs the package defined by the \`pkg_name\` group variable on all \`webservers\` hosts, then run it."
    hint="Use the yum or apt module with name: '{{ pkg_name }}'. The variable pkg_name must already be set in your inventory (e.g. pkg_name=nginx under [webservers:vars])."
    inst1="Use the <span class=\"bold-green-text\">package</span> module with <span class=\"bold-green-text\">name: \"{{ pkg_name }}\"</span> — the variable is resolved from the inventory group vars at runtime:"
    inst2="Run the playbook with <span class=\"bold-green-text\">become: yes</span> — installing packages requires root privileges:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui installe le paquet défini par la variable de groupe \`pkg_name\` sur tous les hôtes \`webservers\`, puis exécutez-le."
    hint="Utilisez le module yum ou apt avec name: '{{ pkg_name }}'. La variable pkg_name doit déjà être définie dans votre inventaire (ex. pkg_name=nginx sous [webservers:vars])."
    inst1="Utilisez le module <span class=\"bold-green-text\">package</span> avec <span class=\"bold-green-text\">name: \"{{ pkg_name }}\"</span> — la variable est résolue depuis les variables de groupe de l'inventaire à l'exécution :"
    inst2="Exécutez le playbook avec <span class=\"bold-green-text\">become: yes</span> — l'installation de paquets nécessite les droits root :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

# Handle the case user skipped adding pkg_name group variable (q67)
if ! grep -q "pkg_name" /home/ansible_user/workspace/inventory 2>/dev/null; then
  grep -q '\[webservers:vars\]' /home/ansible_user/workspace/inventory || printf '\n[webservers:vars]\n' >> /home/ansible_user/workspace/inventory
  echo 'pkg_name=nginx' >> /home/ansible_user/workspace/inventory
fi

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
