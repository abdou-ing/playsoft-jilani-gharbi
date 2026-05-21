#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/roles/requirements.yml\` that specifies two roles to download: one named \`balancer\` from geerlingguy's ansible-role-apache archive, and one named \`phpinfo\` from geerlingguy's ansible-role-php archive. Install them using ansible-galaxy."
    hint="Use \`ansible-galaxy install -r roles/requirements.yml -p roles/\` to install. The \`src\` field must be the full URL to the .tar.gz archive."
    inst1="Create /home/ansible_user/workspace/roles/requirements.yml:"
    inst2="Install the roles from the requirements file:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/roles/requirements.yml\` qui spécifie deux rôles à télécharger : un nommé \`balancer\` depuis l'archive ansible-role-apache de geerlingguy, et un nommé \`phpinfo\` depuis l'archive ansible-role-php de geerlingguy. Installez-les avec ansible-galaxy."
    hint="Utilisez \`ansible-galaxy install -r roles/requirements.yml -p roles/\` pour installer. Le champ \`src\` doit être l'URL complète de l'archive .tar.gz."
    inst1="Créez /home/ansible_user/workspace/roles/requirements.yml :"
    inst2="Installez les rôles depuis le fichier requirements :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_requirements='```yaml
---
- src: https://github.com/geerlingguy/ansible-role-apache/archive/master.tar.gz
  name: balancer

- src: https://github.com/geerlingguy/ansible-role-php/archive/master.tar.gz
  name: phpinfo
```'

cmd_install='```bash
cd ~/playbooks
ansible-galaxy install -r roles/requirements.yml -p roles/
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_requirements" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_install" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,galaxy,roles,requirements"}'
