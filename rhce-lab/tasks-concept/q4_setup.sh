#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/register_when.yml"
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
- name: check ssh status and print result
  hosts: all
  tasks:
    - name: get ssh service status
      command: systemctl is-active ssh
      ignore_errors: yes
      register: result

    - name: print ssh status
      debug:
        msg: "SSH is active on {{ inventory_hostname }}"
      when: result.rc == 0
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/register_when.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that checks whether the \`ssh\` service is active on \`all\` hosts using \`command: systemctl is-active ssh\`. Register the result, then print a debug message only if the return code is 0. Use \`ignore_errors: yes\` so the play continues regardless."
    hint="Use 'register: result' to store the command output. The return code is available as 'result.rc'. Add 'ignore_errors: yes' to the command task so the playbook continues even if ssh is not active. The debug task should have 'when: result.rc == 0'."
    inst1="Create the playbook — use <span class=\"bold-green-text\">register:</span> to capture the command output and <span class=\"bold-green-text\">ignore_errors: yes</span> to continue on failure:"
    inst2="Run the playbook — the debug task prints only when ssh is active (return code 0):"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui vérifie si le service \`ssh\` est actif sur \`all\` les hôtes via \`command: systemctl is-active ssh\`. Enregistrez le résultat, puis affichez un message debug uniquement si le code de retour est 0. Utilisez \`ignore_errors: yes\` pour que le play continue dans tous les cas."
    hint="Utilisez 'register: result' pour stocker la sortie de la commande. Le code de retour est accessible via 'result.rc'. Ajoutez 'ignore_errors: yes' à la tâche command. La tâche debug doit avoir 'when: result.rc == 0'."
    inst1="Créez le playbook — utilisez <span class=\"bold-green-text\">register:</span> pour capturer la sortie et <span class=\"bold-green-text\">ignore_errors: yes</span> pour continuer en cas d'échec :"
    inst2="Exécutez le playbook — la tâche debug s'affiche uniquement quand ssh est actif (code retour 0) :"
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
    "tags": "ansible,register,when,ignore_errors,debug,conditional"
  }'
