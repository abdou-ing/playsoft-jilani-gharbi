#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/failed_when.yml"
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
- name: demonstrate failed_when
  hosts: webservers
  tasks:
    - name: run a command
      command: echo "this task has failed"
      register: command_result
      ignore_errors: yes
      failed_when: "'failed' in command_result.stdout"

    - name: show playbook continued
      debug:
        msg: "Playbook continued despite task failure"
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/failed_when.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs \`echo \"this task has failed\"\` on \`webservers\`, registers the output, and uses \`failed_when\` to mark the task as failed when the word \`failed\` appears in stdout. Add \`ignore_errors: yes\` so the playbook continues and shows a debug message after the failed task."
    hint="Use 'register: command_result' to capture output, then 'failed_when: \"'failed' in command_result.stdout\"' to define a custom failure condition. Add 'ignore_errors: yes' to allow the next task to run despite the failure."
    inst1="Create the playbook — use <span class=\"bold-green-text\">register:</span>, <span class=\"bold-green-text\">failed_when:</span>, and <span class=\"bold-green-text\">ignore_errors: yes</span> on the command task, then add a debug task:"
    inst2="Run the playbook — observe that the first task fails (due to failed_when) but the debug task still runs (due to ignore_errors):"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui exécute \`echo \"this task has failed\"\` sur \`webservers\`, enregistre la sortie, et utilise \`failed_when\` pour marquer la tâche comme échouée quand le mot \`failed\` apparaît dans stdout. Ajoutez \`ignore_errors: yes\` pour que le playbook continue et affiche un message debug après la tâche échouée."
    hint="Utilisez 'register: command_result' pour capturer la sortie, puis 'failed_when: \"'failed' in command_result.stdout\"' pour définir une condition d'échec personnalisée. Ajoutez 'ignore_errors: yes' pour permettre à la tâche suivante de s'exécuter."
    inst1="Créez le playbook — utilisez <span class=\"bold-green-text\">register:</span>, <span class=\"bold-green-text\">failed_when:</span> et <span class=\"bold-green-text\">ignore_errors: yes</span> sur la tâche command, puis ajoutez une tâche debug :"
    inst2="Exécutez le playbook — observez que la première tâche échoue (à cause de failed_when) mais la tâche debug s'exécute quand même (grâce à ignore_errors) :"
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
    "tags": "ansible,failed_when,register,ignore_errors,error_handling,playbook"
  }'
