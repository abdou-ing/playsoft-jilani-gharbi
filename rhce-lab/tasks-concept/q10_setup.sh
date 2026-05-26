#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/fail_demo.yml"
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
- name: check OS compatibility with fail module
  hosts: webservers
  vars:
    required_os: "Ubuntu"
  tasks:
    - name: fail if OS is not supported
      fail:
        msg: "Host {{ inventory_hostname }} runs {{ ansible_facts["distribution"] }} — not supported. Required: {{ required_os }}"
      when: ansible_facts["distribution"] != required_os

    - name: OS check passed
      debug:
        msg: "{{ inventory_hostname }} is running {{ ansible_facts["distribution"] }} — OK"
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/fail_demo.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that uses the \`fail\` module on \`webservers\`. Define a variable \`required_os: \"Ubuntu\"\`, then use \`fail:\` with a descriptive \`msg:\` to abort if \`ansible_facts['distribution']\` does not match \`required_os\`. Add a debug task that confirms the OS check passed. Run the playbook."
    hint="The 'fail' module aborts the play with a custom message. Combine it with 'when:' to make it conditional. Unlike 'assert', 'fail' has no automatic message — you must write one in 'msg:'. Since all hosts run Ubuntu, the fail task will be skipped and the debug task will run."
    inst1="Create the playbook — use the <span class=\"bold-green-text\">fail:</span> module with <span class=\"bold-green-text\">msg:</span> and a <span class=\"bold-green-text\">when:</span> condition, then add a debug task for success:"
    inst2="Run the playbook — the fail task is skipped on Ubuntu hosts and the debug task confirms the OS check:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui utilise le module \`fail\` sur \`webservers\`. Définissez une variable \`required_os: \"Ubuntu\"\`, puis utilisez \`fail:\` avec un \`msg:\` descriptif pour interrompre si \`ansible_facts['distribution']\` ne correspond pas à \`required_os\`. Ajoutez une tâche debug qui confirme le succès. Exécutez le playbook."
    hint="Le module 'fail' interrompt le play avec un message personnalisé. Combinez-le avec 'when:' pour le rendre conditionnel. Contrairement à 'assert', 'fail' n'a pas de message automatique — vous devez en écrire un dans 'msg:'. Comme tous les hôtes tournent sous Ubuntu, la tâche fail sera passée et la tâche debug s'exécutera."
    inst1="Créez le playbook — utilisez le module <span class=\"bold-green-text\">fail:</span> avec <span class=\"bold-green-text\">msg:</span> et une condition <span class=\"bold-green-text\">when:</span>, puis ajoutez une tâche debug pour le succès :"
    inst2="Exécutez le playbook — la tâche fail est passée sur les hôtes Ubuntu et la tâche debug confirme la vérification de l'OS :"
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
    "tags": "ansible,fail,when,distribution,error_handling,playbook"
  }'
