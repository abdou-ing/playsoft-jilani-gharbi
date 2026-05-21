#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/vars_demo.yml"
inventory_path="/home/ansible_user/workspace/inventory"

# Skip-q60 guard
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
- name: display a variable
  hosts: all
  vars:
    greeting: "Hello from Ansible"
  tasks:
    - name: print greeting
      debug:
        msg: "{{ greeting }}"
```'

cmd2="ansible-playbook -i /home/ansible_user/workspace/inventory /home/ansible_user/workspace/vars_demo.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that defines a \`greeting\` variable with the value \`Hello from Ansible\` in the \`vars:\` section, then uses the \`debug\` module to print it on all hosts. Run the playbook."
    hint="Use vars: at the play level to define the variable, then reference it with \"{{ greeting }}\" in the debug msg: field. Quotes around {{ }} are required in YAML."
    inst1="Create the playbook at <span class=\"bold-green-text\">$pb_path</span> with a <span class=\"bold-green-text\">vars:</span> section and a <span class=\"bold-green-text\">debug</span> task that prints <span class=\"bold-green-text\">greeting</span>:"
    inst2="Run the playbook — every host should print the greeting message:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui définit une variable \`greeting\` avec la valeur \`Hello from Ansible\` dans la section \`vars:\`, puis utilise le module \`debug\` pour l'afficher sur tous les hôtes. Exécutez le playbook."
    hint="Utilisez vars: au niveau du jeu pour définir la variable, puis référencez-la avec \"{{ greeting }}\" dans le champ msg: de debug. Les guillemets autour de {{ }} sont requis en YAML."
    inst1="Créez le playbook à <span class=\"bold-green-text\">$pb_path</span> avec une section <span class=\"bold-green-text\">vars:</span> et une tâche <span class=\"bold-green-text\">debug</span> qui affiche <span class=\"bold-green-text\">greeting</span> :"
    inst2="Exécutez le playbook — chaque hôte doit afficher le message de salutation :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
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
    "tags": "ansible,variables,vars,debug,playbook"
  }'
