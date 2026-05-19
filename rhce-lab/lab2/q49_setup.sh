#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory_path="/home/ansible_user/inventory"

case "$lang" in
  en)
    question="Create an Ansible inventory file at \`$inventory_path\` with \`web1\` and \`web2\` under group \`[webservers]\`."
    hint="An inventory file uses INI format. Section header like \`[webservers]\` defines a group, and hostnames are listed beneath it."
    inst1="Create the inventory file with the following content:"
    ;;
  fr)
    question="Créez un fichier d'inventaire Ansible à \`$inventory_path\` avec \`web1\` et \`web2\` dans le groupe \`[webservers]\`."
    hint="Un fichier d'inventaire utilise le format INI. L'en-tête de section comme \`[webservers]\` définit un groupe, et les noms d'hôtes sont listés en dessous."
    inst1="Créez le fichier d'inventaire avec le contenu suivant :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac

code_block='
```ini
[webservers]
web1
web2
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" \
  --arg cmd1 "$code_block" \
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
    "tags": "ansible,rhce,inventory"
  }'
