#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/force_handler.yml"
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

# Create source file for the first copy task
printf 'force handler source\n' > /tmp/force_src.txt

cmd1='```yaml
---
- name: demonstrate force_handlers
  hosts: webservers
  force_handlers: yes
  tasks:
    - name: copy existing file (triggers handler)
      copy:
        src: /tmp/force_src.txt
        dest: /tmp/force_copy.txt
      notify: mark_done

    - name: copy nonexistent file (will fail)
      copy:
        src: /tmp/this_does_not_exist.txt
        dest: /tmp/nowhere.txt

  handlers:
    - name: mark_done
      shell: echo "handler ran despite failure" > /tmp/handler_forced.log
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/force_handler.yml; echo exit: $?"
cmd3="ansible webservers -i ~/workspace/inventory -m command -a 'cat /tmp/handler_forced.log'"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that uses \`force_handlers: yes\`. The first task copies \`/tmp/force_src.txt\` to \`/tmp/force_copy.txt\` on \`webservers\` and notifies the handler \`mark_done\`. The second task copies a nonexistent file (which will fail). The handler must write to \`/tmp/handler_forced.log\`. Run it and observe that the handler runs even though the play fails."
    hint="Without force_handlers: yes, a handler would not run if any task after its notification fails. Set force_handlers: yes in the play header to guarantee the handler always runs when notified, regardless of subsequent task failures."
    inst1="Create the playbook with <span class=\"bold-green-text\">force_handlers: yes</span> in the play header, two tasks (one succeeds, one fails), and a handler that writes a log file:"
    inst2="Run the playbook — it will fail on the second task, but the handler still runs because of <span class=\"bold-green-text\">force_handlers: yes</span>:"
    inst3="Verify the handler wrote to <span class=\"bold-green-text\">/tmp/handler_forced.log</span> despite the playbook failure:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui utilise \`force_handlers: yes\`. La première tâche copie \`/tmp/force_src.txt\` vers \`/tmp/force_copy.txt\` sur \`webservers\` et notifie le handler \`mark_done\`. La seconde tâche copie un fichier inexistant (qui échouera). Le handler doit écrire dans \`/tmp/handler_forced.log\`. Exécutez-le et observez que le handler s'exécute malgré l'échec du play."
    hint="Sans force_handlers: yes, un handler ne s'exécuterait pas si une tâche après sa notification échoue. Définissez force_handlers: yes dans l'en-tête du play pour garantir que le handler s'exécute toujours quand il est notifié, peu importe les échecs suivants."
    inst1="Créez le playbook avec <span class=\"bold-green-text\">force_handlers: yes</span> dans l'en-tête, deux tâches (une réussit, une échoue), et un handler qui écrit un fichier log :"
    inst2="Exécutez le playbook — il échouera sur la deuxième tâche, mais le handler s'exécute quand même grâce à <span class=\"bold-green-text\">force_handlers: yes</span> :"
    inst3="Vérifiez que le handler a écrit dans <span class=\"bold-green-text\">/tmp/handler_forced.log</span> malgré l'échec du playbook :"
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
    "tags": "ansible,force_handlers,handlers,notify,error_handling,playbook"
  }'
