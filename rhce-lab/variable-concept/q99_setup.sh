#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/full_setup.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs on \`webservers\` with \`become: yes\`, installs the \`pkg_name\` package, and ensures the service is both \`started\` AND \`enabled\` at boot. Then run it."
    hint="The service module has both state: and enabled: parameters. Set state: started and enabled: yes in the same task to cover both requirements."
    inst1="Create the full setup playbook with service enabled at boot:"
    cmd1='---
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
        enabled: yes'
    inst2="Run the playbook and verify the service is enabled:"
    cmd2="ansible-playbook ~/full_setup.yml
ansible webservers -m command -a 'systemctl is-enabled nginx'"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui s'exécute sur \`webservers\` avec \`become: yes\`, installe le paquet \`pkg_name\`, et s'assure que le service est à la fois \`démarré\` ET \`activé\` au démarrage. Puis exécutez-le."
    hint="Le module service a les paramètres state: et enabled:. Définissez state: started et enabled: yes dans la même tâche pour couvrir les deux exigences."
    inst1="Créez le playbook de configuration complète avec le service activé au démarrage :"
    cmd1='---
- name: configuration complète du service
  hosts: webservers
  become: yes
  tasks:
    - name: installer le paquet
      package:
        name: "{{ pkg_name }}"
        state: present
    - name: démarrer et activer le service au démarrage
      service:
        name: "{{ pkg_name }}"
        state: started
        enabled: yes'
    inst2="Exécutez le playbook et vérifiez que le service est activé :"
    cmd2="ansible-playbook ~/full_setup.yml
ansible webservers -m command -a 'systemctl is-enabled nginx'"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

# Handle the case user skipped adding pkg_name group variable (q90)
if ! grep -q "pkg_name" /home/ansible_user/inventory 2>/dev/null; then
  grep -q '\[webservers:vars\]' /home/ansible_user/inventory || printf '\n[webservers:vars]\n' >> /home/ansible_user/inventory
  echo 'pkg_name=nginx' >> /home/ansible_user/inventory
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
