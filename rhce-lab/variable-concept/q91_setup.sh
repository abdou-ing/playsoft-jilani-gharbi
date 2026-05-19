#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/debug_vars.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that runs on the \`webservers\` group and uses the \`debug\` module to print the value of the \`pkg_name\` variable."
    hint="The debug module accepts either \`msg:\` with a Jinja2 expression or \`var:\` with a bare variable name. Make sure pkg_name is already set in your inventory as a group variable."
    inst1="Create the playbook and run it to verify the variable is printed:"
    cmd1='---
- name: print pkg_name variable
  hosts: webservers
  tasks:
    - name: display pkg_name
      debug:
        var: pkg_name'
    inst2="Run the playbook to confirm the output:"
    cmd2="ansible-playbook ~/debug_vars.yml"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui s'exécute sur le groupe \`webservers\` et utilise le module \`debug\` pour afficher la valeur de la variable \`pkg_name\`."
    hint="Le module debug accepte soit \`msg:\` avec une expression Jinja2, soit \`var:\` avec un nom de variable nu. Assurez-vous que pkg_name est déjà défini dans votre inventaire comme variable de groupe."
    inst1="Créez le playbook et exécutez-le pour vérifier que la variable est affichée :"
    cmd1='---
- name: afficher la variable pkg_name
  hosts: webservers
  tasks:
    - name: afficher pkg_name
      debug:
        var: pkg_name'
    inst2="Exécutez le playbook pour confirmer la sortie :"
    cmd2="ansible-playbook ~/debug_vars.yml"
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
    "tags": "ansible,variables,debug,playbook"
  }'
