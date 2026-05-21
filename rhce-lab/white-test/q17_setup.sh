#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/mycollections/requirements.yml\` specifying collections \`ansible.posix\` and \`community.general\`. Install them to \`/home/ansible_user/workspace/mycollections/\` using: \`ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/\`"
    hint="The requirements.yml for collections uses a \`collections:\` list with \`name:\` entries. After installation, the collections will be in \`mycollections/ansible_collections/\` directory."
    inst1="Create /home/ansible_user/workspace/mycollections/requirements.yml:"
    inst2="Install the collections:"
    inst3="Verify installation:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/mycollections/requirements.yml\` spécifiant les collections \`ansible.posix\` et \`community.general\`. Installez-les dans \`/home/ansible_user/workspace/mycollections/\` en utilisant : \`ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/\`"
    hint="Le requirements.yml pour les collections utilise une liste \`collections:\` avec des entrées \`name:\`. Après installation, les collections seront dans le répertoire \`mycollections/ansible_collections/\`."
    inst1="Créez /home/ansible_user/workspace/mycollections/requirements.yml :"
    inst2="Installez les collections :"
    inst3="Vérifiez l'installation :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_requirements='```yaml
---
collections:
  - name: ansible.posix
  - name: community.general
```'

cmd_install='```bash
mkdir -p /home/ansible_user/workspace/mycollections
cd ~/playbooks
ansible-galaxy collection install -r mycollections/requirements.yml -p mycollections/
```'

cmd_verify='```bash
ls /home/ansible_user/workspace/mycollections/ansible_collections/
ansible-galaxy collection list --collections-path /home/ansible_user/workspace/mycollections/
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_requirements" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_install" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_verify" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,galaxy,collections,ansible.posix,community.general"}'
