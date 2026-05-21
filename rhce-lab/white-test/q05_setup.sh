#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create an Ansible role named \`apache\` in \`/home/ansible_user/workspace/roles/apache/\` that installs apache2, enables and starts it, allows port 80 via ufw, and deploys an index.html template. Create \`/home/ansible_user/workspace/newrole.yml\` that applies this role to the \`webservers\` group."
    hint="The template in \`roles/apache/templates/index.html.j2\` should use \`ansible_facts['fqdn']\` and \`ansible_facts['default_ipv4']['address']\`. Use the \`community.general.ufw\` module for the firewall rule."
    inst1="Create the role directory structure:"
    inst2="Create roles/apache/tasks/main.yml:"
    inst3="Create roles/apache/templates/index.html.j2:"
    inst4="Create roles/apache/vars/main.yml:"
    inst5="Create the playbook /home/ansible_user/workspace/newrole.yml and run it:"
    ;;
  fr)
    question="Créez un rôle Ansible nommé \`apache\` dans \`/home/ansible_user/workspace/roles/apache/\` qui installe apache2, l'active et le démarre, autorise le port 80 via ufw, et déploie un template index.html. Créez \`/home/ansible_user/workspace/newrole.yml\` qui applique ce rôle au groupe \`webservers\`."
    hint="Le template dans \`roles/apache/templates/index.html.j2\` doit utiliser \`ansible_facts['fqdn']\` et \`ansible_facts['default_ipv4']['address']\`. Utilisez le module \`community.general.ufw\` pour la règle de pare-feu."
    inst1="Créez la structure de répertoires du rôle :"
    inst2="Créez roles/apache/tasks/main.yml :"
    inst3="Créez roles/apache/templates/index.html.j2 :"
    inst4="Créez roles/apache/vars/main.yml :"
    inst5="Créez le playbook /home/ansible_user/workspace/newrole.yml et exécutez-le :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_mkdir='```bash
mkdir -p /home/ansible_user/workspace/roles/apache/{tasks,templates,vars,handlers}
```'

cmd_tasks='```yaml
---
- name: Install apache2
  ansible.builtin.apt:
    name: "{{ pkgs }}"
    state: present
    update_cache: true

- name: Enable and start apache2
  ansible.builtin.service:
    name: apache2
    state: started
    enabled: true

- name: Allow http through ufw
  community.general.ufw:
    rule: allow
    name: "{{ item }}"
  loop: "{{ rule }}"

- name: Deploy index.html template
  ansible.builtin.template:
    src: index.html.j2
    dest: /var/www/html/index.html
    owner: www-data
    group: www-data
    mode: "0644"
```'

cmd_template='```html
Welcome to {{ ansible_facts["fqdn"] }} on {{ ansible_facts["default_ipv4"]["address"] }}
```'

cmd_vars='```yaml
---
pkgs:
  - apache2

rule:
  - http
```'

cmd_playbook='```yaml
- name: Apply apache role to webservers
  hosts: webservers
  become: true
  roles:
    - apache
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_mkdir" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_tasks" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_template" \
  --arg inst4 "$inst4" --arg cmd4 "$cmd_vars" \
  --arg inst5 "$inst5" --arg cmd5 "$cmd_playbook" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}, {"instruction": $inst4, "command": $cmd4}, {"instruction": $inst5, "command": $cmd5}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,role,apache2,template,ufw"}'
