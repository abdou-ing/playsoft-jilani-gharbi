#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/handler_demo.yml"
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

# Create source file for the handler demo
printf 'Managed by Ansible\n' > /tmp/notify_src.txt

cmd1='```yaml
---
- name: demonstrate handlers with notify
  hosts: webservers
  tasks:
    - name: copy file to webservers
      copy:
        src: /tmp/notify_src.txt
        dest: /tmp/handler_dest.txt
      notify: write_log

  handlers:
    - name: write_log
      shell: echo "handler triggered at $(date)" > /tmp/handler.log
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/handler_demo.yml"
cmd3="ansible webservers -i ~/workspace/inventory -m command -a 'cat /tmp/handler.log'"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that copies \`/tmp/notify_src.txt\` to \`/tmp/handler_dest.txt\` on \`webservers\` and uses \`notify\` to trigger a handler named \`write_log\`. The handler must write a message to \`/tmp/handler.log\` using the \`shell\` module. Run the playbook and verify the log file."
    hint="Handlers are defined in a 'handlers:' section at the end of the play, at the same level as 'tasks:'. The notify: value must exactly match the handler's name:. Handlers only run if the task that triggers them generates a 'changed' status."
    inst1="Create the playbook with a <span class=\"bold-green-text\">notify:</span> on the copy task and a <span class=\"bold-green-text\">handlers:</span> section at the end:"
    inst2="Run the playbook — the handler runs only if the copy task results in a <span class=\"bold-green-text\">changed</span> status:"
    inst3="Verify the handler wrote to <span class=\"bold-green-text\">/tmp/handler.log</span> on all webservers:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui copie \`/tmp/notify_src.txt\` vers \`/tmp/handler_dest.txt\` sur \`webservers\` et utilise \`notify\` pour déclencher un handler nommé \`write_log\`. Le handler doit écrire un message dans \`/tmp/handler.log\` via le module \`shell\`. Exécutez le playbook et vérifiez le fichier log."
    hint="Les handlers sont définis dans une section 'handlers:' à la fin du play, au même niveau que 'tasks:'. La valeur de notify: doit correspondre exactement au name: du handler. Les handlers ne s'exécutent que si la tâche qui les déclenche a le statut 'changed'."
    inst1="Créez le playbook avec <span class=\"bold-green-text\">notify:</span> sur la tâche copy et une section <span class=\"bold-green-text\">handlers:</span> à la fin :"
    inst2="Exécutez le playbook — le handler s'exécute uniquement si la tâche copy a le statut <span class=\"bold-green-text\">changed</span> :"
    inst3="Vérifiez que le handler a écrit dans <span class=\"bold-green-text\">/tmp/handler.log</span> sur tous les webservers :"
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
    "tags": "ansible,handlers,notify,copy,shell,playbook"
  }'
