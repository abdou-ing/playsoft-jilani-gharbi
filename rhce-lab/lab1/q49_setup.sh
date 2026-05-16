#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory_path="/home/ansible_user/inventory"

case "$lang" in
  en)
    question="Create an Ansible inventory file at \`$inventory_path\` with \`web1\` under group \`[webservers1]\` and \`web2\` under group \`[webservers2]\`."
    hint="An inventory file uses INI format. Each section header like \`[webservers1]\` defines a group, and hostnames are listed beneath it."
    inst1="Create the inventory file with both host groups:"
    ;;
  fr)
    question="Créez un fichier d'inventaire Ansible à \`$inventory_path\` avec \`web1\` dans le groupe \`[webservers1]\` et \`web2\` dans le groupe \`[webservers2]\`."
    hint="Un fichier d'inventaire utilise le format INI. Chaque en-tête de section comme \`[webservers1]\` définit un groupe, et les noms d'hôtes sont listés en dessous."
    inst1="Créez le fichier d'inventaire avec les deux groupes d'hôtes :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac

cmd_inventory="$(cat <<'INVENTORY'
```bash
cat > /home/ansible_user/inventory << EOF
[webservers1]
web1

[webservers2]
web2
EOF
```
INVENTORY
)"

instructions=$(jq -n \
  --arg inst1 "$inst1" \
  --arg cmd1 "$cmd_inventory" \
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
