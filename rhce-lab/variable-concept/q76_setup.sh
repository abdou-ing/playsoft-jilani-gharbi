#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/full_setup.yml"

cmd1='```yaml
---
- name: full service setup
  hosts: webservers
  become: yes
  tasks:
    - name: install package
      package:
        name: "{{ pkg_name }}"
        state: present
    - name: start and enable service at boot
      service:
        name: "{{ pkg_name }}"
        state: started
        enabled: yes
```'
cmd2="ansible-playbook /home/ansible_user/workspace/full_setup.yml
ansible webservers -m command -a 'systemctl is-enabled nginx'"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs on \`webservers\` with \`become: yes\`, installs the \`pkg_name\` package, and ensures the service is both \`started\` AND \`enabled\` at boot. Then run it."
    hint="The service module has both state: and enabled: parameters. Set state: started and enabled: yes in the same task to cover both requirements."
    inst1="Create the playbook with <span class=\"bold-green-text\">become: yes</span>, using the <span class=\"bold-green-text\">package</span> module to install and the <span class=\"bold-green-text\">service</span> module with both <span class=\"bold-green-text\">state: started</span> and <span class=\"bold-green-text\">enabled: yes</span>:"
    inst2="Run the playbook and confirm the service is enabled at boot with <span class=\"bold-green-text\">systemctl is-enabled</span>:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui s'exécute sur \`webservers\` avec \`become: yes\`, installe le paquet \`pkg_name\`, et s'assure que le service est à la fois \`démarré\` ET \`activé\` au démarrage. Puis exécutez-le."
    hint="Le module service a les paramètres state: et enabled:. Définissez state: started et enabled: yes dans la même tâche pour couvrir les deux exigences."
    inst1="Créez le playbook avec <span class=\"bold-green-text\">become: yes</span>, le module <span class=\"bold-green-text\">package</span> pour installer et le module <span class=\"bold-green-text\">service</span> avec <span class=\"bold-green-text\">state: started</span> et <span class=\"bold-green-text\">enabled: yes</span> :"
    inst2="Exécutez le playbook et confirmez que le service est activé au démarrage avec <span class=\"bold-green-text\">systemctl is-enabled</span> :"
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
    "tags": "ansible,service,become,enabled,playbook"
  }'
