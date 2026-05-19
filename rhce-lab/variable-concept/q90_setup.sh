#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory_path="/home/ansible_user/inventory"

case "$lang" in
  en)
    question="Add the group variable \`pkg_name=nginx\` to the \`webservers\` group in the inventory file at \`$inventory_path\`."
    hint="Use the \`[webservers:vars]\` section to define group-level variables that apply to every host in the group."
    inst1="Add a [webservers:vars] block below the [webservers] section in your inventory file:"
    cmd1="# Example inventory layout:
[webservers]
web1
web2

[webservers:vars]
pkg_name=nginx"
    ;;
  fr)
    question="Ajoutez la variable de groupe \`pkg_name=nginx\` au groupe \`webservers\` dans le fichier d'inventaire \`$inventory_path\`."
    hint="Utilisez la section \`[webservers:vars]\` pour définir des variables au niveau du groupe qui s'appliquent à chaque hôte du groupe."
    inst1="Ajoutez un bloc [webservers:vars] sous la section [webservers] dans votre fichier d'inventaire :"
    cmd1="# Exemple de structure d'inventaire :
[webservers]
web1
web2

[webservers:vars]
pkg_name=nginx"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  '[{"instruction": $inst1, "command": $cmd1}]')

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
    "tags": "ansible,variables,inventory"
  }'
