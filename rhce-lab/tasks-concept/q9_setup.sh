#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/block_rescue.yml"
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
- name: demonstrate block rescue always
  hosts: webservers
  tasks:
    - name: block with error handling
      block:
        - name: try to read a missing file (will fail)
          shell: cat /tmp/this_file_does_not_exist.txt

      rescue:
        - name: create rescue file on failure
          shell: echo "rescued" > /tmp/rescue_output.txt

      always:
        - name: always print this message
          debug:
            msg: "This always runs regardless of block success or failure"
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/block_rescue.yml"
cmd3="ansible webservers -i ~/workspace/inventory -m command -a 'cat /tmp/rescue_output.txt'"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` on \`webservers\` that uses \`block\`, \`rescue\`, and \`always\`. The block tries to read a nonexistent file (which will fail). The rescue section creates \`/tmp/rescue_output.txt\` with content \`rescued\`. The always section prints a debug message. Run the playbook."
    hint="block/rescue/always works like try/catch/finally: if any task in the block fails, tasks in rescue run instead. Tasks in always run no matter what. Indent block, rescue, and always at the same level under the task name."
    inst1="Create the playbook with <span class=\"bold-green-text\">block:</span>, <span class=\"bold-green-text\">rescue:</span>, and <span class=\"bold-green-text\">always:</span> sections:"
    inst2="Run the playbook — the block task fails but rescue handles it and always runs in both cases:"
    inst3="Verify the rescue task created <span class=\"bold-green-text\">/tmp/rescue_output.txt</span> on webservers:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` sur \`webservers\` qui utilise \`block\`, \`rescue\` et \`always\`. Le block essaie de lire un fichier inexistant (qui échouera). La section rescue crée \`/tmp/rescue_output.txt\` avec le contenu \`rescued\`. La section always affiche un message debug. Exécutez le playbook."
    hint="block/rescue/always fonctionne comme try/catch/finally : si une tâche du block échoue, les tâches de rescue s'exécutent à la place. Les tâches de always s'exécutent dans tous les cas. Indentez block, rescue et always au même niveau sous le nom de la tâche."
    inst1="Créez le playbook avec les sections <span class=\"bold-green-text\">block:</span>, <span class=\"bold-green-text\">rescue:</span> et <span class=\"bold-green-text\">always:</span> :"
    inst2="Exécutez le playbook — la tâche du block échoue mais rescue la prend en charge et always s'exécute dans tous les cas :"
    inst3="Vérifiez que la tâche rescue a créé <span class=\"bold-green-text\">/tmp/rescue_output.txt</span> sur webservers :"
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
    "tags": "ansible,block,rescue,always,error_handling,playbook"
  }'
