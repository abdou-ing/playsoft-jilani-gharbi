#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

cfg_path="/home/ansible_user/ansible.cfg"
inventory_path="/home/ansible_user/inventory"

case "$lang" in
  en)
    question="Create the Ansible configuration file at \`$cfg_path\` setting \`remote_user=ansible_user\`, pointing to the inventory at \`$inventory_path\`, and enabling privilege escalation with \`become=true\`."
    hint="The \`ansible.cfg\` file uses INI format with \`[defaults]\` and \`[privilege_escalation]\` sections."
    inst1="Create ansible.cfg with the required settings:"
    ;;
  fr)
    question="Créez le fichier de configuration Ansible à \`$cfg_path\` en définissant \`remote_user=ansible_user\`, en pointant vers l'inventaire à \`$inventory_path\` et en activant l'élévation de privilèges avec \`become=true\`."
    hint="Le fichier \`ansible.cfg\` utilise le format INI avec les sections \`[defaults]\` et \`[privilege_escalation]\`."
    inst1="Créez ansible.cfg avec les paramètres requis :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac
cmd_cfg='```bash
cat > ~/ansible.cfg << EOF
[defaults]
remote_user=ansible_user
inventory=/home/ansible_user/inventory

[privilege_escalation]
become=true
become_ask_pass=false
EOF
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" \
  --arg cmd1 "$cmd_cfg" \
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
    "tags": "ansible,rhce,configuration"
  }'
