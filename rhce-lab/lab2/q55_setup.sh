#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write a multi-play playbook at \`~/playbooks/webserver.yml\`: (1) install \`apache2\` on \`webservers1\`, (2) verify installation on all hosts using the \`command\` module with \`dpkg -l apache2\`, (3) start and enable the \`apache2\` service on \`webservers1\`."
    hint="Use \`apt\` module to install, \`command\` module to verify, and \`service\` module to manage the service. Each play targets a different host group."
    inst1="Create the playbook at ~/playbooks/webserver.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook multi-play dans \`~/playbooks/webserver.yml\` : (1) installez \`apache2\` sur \`webservers1\`, (2) vérifiez l'installation sur tous les hôtes avec le module \`command\` en utilisant \`dpkg -l apache2\`, (3) démarrez et activez le service \`apache2\` sur \`webservers1\`."
    hint="Utilisez le module \`apt\` pour installer, le module \`command\` pour vérifier, et le module \`service\` pour gérer le service. Chaque play cible un groupe d'hôtes différent."
    inst1="Créez le playbook dans ~/playbooks/webserver.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Install apache2 on webservers1
  hosts: webservers1
  become: true
  tasks:
    - name: Install apache2
      apt:
        name: apache2
        state: present

- name: Verify apache2 on all hosts
  hosts: all
  become: true
  tasks:
    - name: Verify apache2 installation
      command: dpkg -l apache2

- name: Start and enable apache2 on webservers1
  hosts: webservers1
  become: true
  tasks:
    - name: Start and enable apache2
      service:
        name: apache2
        state: started
        enabled: yes
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/webserver.yml
ansible-playbook playbooks/webserver.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,apache2,service"}'
