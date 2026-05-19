#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write a multi-play playbook at \`/home/ansible_user/playbooks/webserver.yml\`: (1) install \`apache2\` on \`webservers\`, (2) install \`vim\` on all managed nodes."
    hint="Use the \`ansible.builtin.apt\` module to install packages. Each play targets a different host group."
    inst1="Create the playbook at /home/ansible_user/playbooks/webserver.yml:"
    inst2="Check the playbook syntax:"
    inst3="Run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook multi-play dans \`/home/ansible_user/playbooks/webserver.yml\` : (1) installez \`apache2\` sur \`webservers\`, (2) installez \`vim\` sur toutes les machines hôtes."
    hint="Utilisez le module \`ansible.builtin.apt\` pour installer les paquets. Chaque play cible un groupe d'hôtes différent."
    inst1="Créez le playbook dans /home/ansible_user/playbooks/webserver.yml :"
    inst2="Vérifiez la syntaxe du playbook :"
    inst3="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Install apache2 on webservers
  hosts: webservers
  become: true
  tasks:
    - name: Update apt-get repo and cache
      ansible.builtin.apt: 
        update_cache: yes 
        cache_valid_time: 3600
    - name: Install apache2
      ansible.builtin.apt:
        name: apache2
        state: present
    - name: Make sure apache service unit is running and enabled
      ansible.builtin.service:
        state: started
        enabled: true
        name: apache2
      
- name: Install vim on all managed hosts
  hosts: all
  become: true
  tasks:
    - name: Install vim
      ansible.builtin.package:
        name: vim
        state: present
```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/webserver.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/webserver.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,apache2,vim"}'
