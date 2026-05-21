#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/debug_vars.yml"

cmd1='```yaml
---
- name: print pkg_name variable
  hosts: webservers
  tasks:
    - name: display pkg_name
      debug:
        var: pkg_name
```'
cmd2="ansible-playbook /home/ansible_user/workspace/debug_vars.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs on the \`webservers\` group and uses the \`debug\` module to print the value of the \`pkg_name\` variable."
    hint="The debug module accepts either \`msg:\` with a Jinja2 expression or \`var:\` with a bare variable name. Make sure pkg_name is already set in your inventory as a group variable."
    inst1="Use the <span class=\"bold-green-text\">debug</span> module with <span class=\"bold-green-text\">var:</span> to print the variable by name — no Jinja2 braces needed with this argument:"
    inst2="Run the playbook and verify the value of <span class=\"bold-green-text\">pkg_name</span> appears in the output:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui s'exécute sur le groupe \`webservers\` et utilise le module \`debug\` pour afficher la valeur de la variable \`pkg_name\`."
    hint="Le module debug accepte soit \`msg:\` avec une expression Jinja2, soit \`var:\` avec un nom de variable nu. Assurez-vous que pkg_name est déjà défini dans votre inventaire comme variable de groupe."
    inst1="Utilisez le module <span class=\"bold-green-text\">debug</span> avec <span class=\"bold-green-text\">var:</span> pour afficher la variable par son nom — aucune accolade Jinja2 n'est nécessaire avec cet argument :"
    inst2="Exécutez le playbook et vérifiez que la valeur de <span class=\"bold-green-text\">pkg_name</span> apparaît dans la sortie :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

# Handle the case user skipped adding pkg_name group variable (q67)
if ! grep -q "pkg_name" /home/ansible_user/workspace/inventory 2>/dev/null; then
  grep -q '\[webservers:vars\]' /home/ansible_user/workspace/inventory || printf '\n[webservers:vars]\n' >> /home/ansible_user/workspace/inventory
  echo 'pkg_name=nginx' >> /home/ansible_user/workspace/inventory
fi

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
    "tags": "ansible,variables,debug,playbook"
  }'
