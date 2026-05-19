#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/multi_task.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` for \`webservers\` that: installs the \`pkg_name\` package, starts and enables the service with the same name, and creates \`/var/www/html/index.html\` with content \`Welcome\`. Then run it."
    hint="You need three tasks: package (or yum/apt), service, and copy. All need become: yes. The service name is the same as pkg_name (nginx)."
    inst1="Create the multi-task playbook:"
    cmd1='---
- name: full web server setup
  hosts: webservers
  become: yes
  tasks:
    - name: install package
      package:
        name: "{{ pkg_name }}"
        state: present
    - name: start and enable service
      service:
        name: "{{ pkg_name }}"
        state: started
        enabled: yes
    - name: create index.html
      copy:
        content: "Welcome"
        dest: /var/www/html/index.html'
    inst2="Run the playbook:"
    cmd2="ansible-playbook ~/multi_task.yml"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` pour \`webservers\` qui : installe le paquet \`pkg_name\`, démarre et active le service du même nom, et crée \`/var/www/html/index.html\` avec le contenu \`Welcome\`. Puis exécutez-le."
    hint="Vous avez besoin de trois tâches : package (ou yum/apt), service et copy. Toutes nécessitent become: yes. Le nom du service est identique à pkg_name (nginx)."
    inst1="Créez le playbook multi-tâches :"
    cmd1='---
- name: configuration complète du serveur web
  hosts: webservers
  become: yes
  tasks:
    - name: installer le paquet
      package:
        name: "{{ pkg_name }}"
        state: present
    - name: démarrer et activer le service
      service:
        name: "{{ pkg_name }}"
        state: started
        enabled: yes
    - name: créer index.html
      copy:
        content: "Welcome"
        dest: /var/www/html/index.html'
    inst2="Exécutez le playbook :"
    cmd2="ansible-playbook ~/multi_task.yml"
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
    "tags": "ansible,service,package,copy,playbook"
  }'
