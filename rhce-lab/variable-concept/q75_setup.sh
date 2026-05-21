#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/check_disk.yml"

cmd1='```yaml
---
- name: check disk usage
  hosts: webservers
  tasks:
    - name: run df -h
      command: df -h
      register: disk_info
    - name: print disk info
      debug:
        var: disk_info.stdout_lines
```'
cmd2="ansible-playbook /home/ansible_user/workspace/check_disk.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs \`df -h\` on all \`webservers\` hosts, stores the output in a variable called \`disk_info\` using \`register:\`, and then prints it using the \`debug\` module. Run the playbook."
    hint="Use the command module to run df -h, then register: disk_info to capture the output. The debug module can print it with var: disk_info.stdout_lines"
    inst1="Create the playbook using the <span class=\"bold-green-text\">command</span> module to run <span class=\"bold-green-text\">df -h</span>, capture the output with <span class=\"bold-green-text\">register: disk_info</span>, and print it with the <span class=\"bold-green-text\">debug</span> module:"
    inst2="Run the playbook and check that <span class=\"bold-green-text\">disk_info.stdout_lines</span> appears in the output for each host:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui exécute \`df -h\` sur tous les hôtes \`webservers\`, stocke la sortie dans une variable nommée \`disk_info\` avec \`register:\`, puis l'affiche avec le module \`debug\`. Exécutez le playbook."
    hint="Utilisez le module command pour exécuter df -h, puis register: disk_info pour capturer la sortie. Le module debug peut l'afficher avec var: disk_info.stdout_lines"
    inst1="Créez le playbook avec le module <span class=\"bold-green-text\">command</span> pour exécuter <span class=\"bold-green-text\">df -h</span>, capturez la sortie avec <span class=\"bold-green-text\">register: disk_info</span> et affichez-la avec le module <span class=\"bold-green-text\">debug</span> :"
    inst2="Exécutez le playbook et vérifiez que <span class=\"bold-green-text\">disk_info.stdout_lines</span> apparaît dans la sortie pour chaque hôte :"
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
