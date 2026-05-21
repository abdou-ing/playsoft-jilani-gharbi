#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Configure Ansible on the control node. Create \`/home/ansible_user/workspace/inventory\` with web1 in \`dev\`, web2 in \`test\`, both in \`prod\`, web1 in \`balancers\`, and \`webservers:children\` = dev, test, prod. Create \`/home/ansible_user/workspace/ansible.cfg\` with the required settings including remote_user=ansible_user, become=true, roles_path, and collections_path."
    hint="Use INI format for the inventory. The ansible.cfg must have [defaults] and [privilege_escalation] sections with all required keys."
    inst1="Create the inventory file at /home/ansible_user/workspace/inventory:"
    inst2="Create the ansible.cfg file at /home/ansible_user/workspace/ansible.cfg:"
    inst3="Test the configuration:"
    ;;
  fr)
    question="Configurez Ansible sur le nœud de contrôle. Créez \`/home/ansible_user/workspace/inventory\` avec web1 dans \`dev\`, web2 dans \`test\`, les deux dans \`prod\`, web1 dans \`balancers\`, et \`webservers:children\` = dev, test, prod. Créez \`/home/ansible_user/workspace/ansible.cfg\` avec les paramètres requis incluant remote_user=ansible_user, become=true, roles_path et collections_path."
    hint="Utilisez le format INI pour l'inventaire. Le fichier ansible.cfg doit avoir les sections [defaults] et [privilege_escalation] avec toutes les clés requises."
    inst1="Créez le fichier d'inventaire /home/ansible_user/workspace/inventory :"
    inst2="Créez le fichier ansible.cfg dans /home/ansible_user/workspace/ansible.cfg :"
    inst3="Testez la configuration :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_inventory='```ini
[dev]
web1

[test]
web2

[prod]
web1
web2

[balancers]
web1

[webservers:children]
dev
test
prod
```'

cmd_cfg='```ini
[defaults]
inventory = inventory
remote_user = ansible_user
roles_path = /home/ansible_user/playbooks/roles
collections_path = /home/ansible_user/playbooks/mycollections
host_key_checking = false

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false
```'

cmd_run='```bash
cd ~/playbooks
ansible all -m ping
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_inventory" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_cfg" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,inventory,ansible.cfg,configuration"}'
