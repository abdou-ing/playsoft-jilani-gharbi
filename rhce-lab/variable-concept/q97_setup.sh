#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory_path="/home/ansible_user/inventory"

case "$lang" in
  en)
    question="Add the group variable \`env=staging\` to the \`webservers\` group in the inventory file at \`$inventory_path\`. Verify it with an ad-hoc command."
    hint="Add env=staging under the [webservers:vars] section. You can verify it is available with: ansible webservers -m debug -a 'var=env'"
    inst1="Add env=staging to the [webservers:vars] section in your inventory:"
    cmd1="# Edit your inventory file and add:
[webservers:vars]
pkg_name=nginx
env=staging"
    inst2="Verify the variable is accessible on all webservers hosts:"
    cmd2="ansible webservers -m debug -a 'var=env'"
    ;;
  fr)
    question="Ajoutez la variable de groupe \`env=staging\` au groupe \`webservers\` dans le fichier d'inventaire \`$inventory_path\`. Vérifiez-la avec une commande ad-hoc."
    hint="Ajoutez env=staging sous la section [webservers:vars]. Vous pouvez vérifier qu'elle est disponible avec : ansible webservers -m debug -a 'var=env'"
    inst1="Ajoutez env=staging à la section [webservers:vars] dans votre inventaire :"
    cmd1="# Modifiez votre fichier d'inventaire et ajoutez :
[webservers:vars]
pkg_name=nginx
env=staging"
    inst2="Vérifiez que la variable est accessible sur tous les hôtes webservers :"
    cmd2="ansible webservers -m debug -a 'var=env'"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

# Handle the case user skipped adding pkg_name group variable (q90)
if ! grep -q "pkg_name" /home/ansible_user/inventory 2>/dev/null; then
  grep -q '\[webservers:vars\]' /home/ansible_user/inventory || printf '\n[webservers:vars]\n' >> /home/ansible_user/inventory
  echo 'pkg_name=nginx' >> /home/ansible_user/inventory
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
    "tags": "ansible,variables,inventory,group-vars"
  }'
