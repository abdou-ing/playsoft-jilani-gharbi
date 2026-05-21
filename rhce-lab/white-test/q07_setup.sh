#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/balance.yml\` with three plays: Play 1 runs on all hosts (gather facts, no tasks); Play 2 runs on \`balancers\` group and uses the \`balancer\` role; Play 3 runs on \`webservers\` group and uses the \`phpinfo\` role."
    hint="Play 1 is needed to gather facts from all hosts before the roles run. Make sure the \`balancer\` and \`phpinfo\` roles are installed from Q6 before running this playbook."
    inst1="Create the playbook /home/ansible_user/workspace/balance.yml:"
    inst2="Check syntax (do not run — roles may have OS-specific issues):"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/balance.yml\` avec trois plays : Play 1 s'exécute sur tous les hôtes (collecte de faits, aucune tâche) ; Play 2 s'exécute sur le groupe \`balancers\` et utilise le rôle \`balancer\` ; Play 3 s'exécute sur le groupe \`webservers\` et utilise le rôle \`phpinfo\`."
    hint="Le Play 1 est nécessaire pour collecter les faits de tous les hôtes avant l'exécution des rôles. Assurez-vous que les rôles \`balancer\` et \`phpinfo\` sont installés depuis la Q6 avant d'exécuter ce playbook."
    inst1="Créez le playbook /home/ansible_user/workspace/balance.yml :"
    inst2="Vérifiez la syntaxe (ne pas exécuter — les rôles peuvent avoir des problèmes spécifiques à l'OS) :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Gather facts from all hosts
  hosts: all
  gather_facts: true
  tasks: []

- name: Apply balancer role to balancers group
  hosts: balancers
  become: true
  roles:
    - balancer

- name: Apply phpinfo role to webservers group
  hosts: webservers
  become: true
  roles:
    - phpinfo
```'

cmd_check='```bash
ansible-playbook --syntax-check playbooks/balance.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,roles,balancer,phpinfo"}'
