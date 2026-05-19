#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/check_disk.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs \`df -h\` on all \`webservers\` hosts, stores the output in a variable called \`disk_info\` using \`register:\`, and then prints it using the \`debug\` module. Run the playbook."
    hint="Use the command module to run df -h, then register: disk_info to capture the output. The debug module can print it with var: disk_info.stdout_lines"
    inst1="Create the playbook with register and debug:"
    cmd1='---
- name: check disk usage
  hosts: webservers
  tasks:
    - name: run df -h
      command: df -h
      register: disk_info
    - name: print disk info
      debug:
        var: disk_info.stdout_lines'
    inst2="Run the playbook:"
    cmd2="ansible-playbook ~/check_disk.yml"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui exécute \`df -h\` sur tous les hôtes \`webservers\`, stocke la sortie dans une variable nommée \`disk_info\` avec \`register:\`, puis l'affiche avec le module \`debug\`. Exécutez le playbook."
    hint="Utilisez le module command pour exécuter df -h, puis register: disk_info pour capturer la sortie. Le module debug peut l'afficher avec var: disk_info.stdout_lines"
    inst1="Créez le playbook avec register et debug :"
    cmd1='---
- name: vérifier l utilisation du disque
  hosts: webservers
  tasks:
    - name: exécuter df -h
      command: df -h
      register: disk_info
    - name: afficher disk_info
      debug:
        var: disk_info.stdout_lines'
    inst2="Exécutez le playbook :"
    cmd2="ansible-playbook ~/check_disk.yml"
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
    "tags": "ansible,register,debug,playbook"
  }'
