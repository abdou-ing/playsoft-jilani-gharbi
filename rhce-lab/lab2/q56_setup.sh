#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"
home_dir="/home/ansible_user"
playbook_dir="$home_dir/playbooks"
repo_url="https://github.com/ansible/ansible-examples.git"

rm -f "$home_dir/result"
mkdir -p "$playbook_dir"


case "$lang" in
  en)
    question="Write an Ansible playbook at \`$playbook_dir/deploy_webapp.yml\` that clones the repository \`$repo_url\` directly to \`/var/www/html\` on the \`webservers\` group using the \`ansible.builtin.git\` module"
    hint="Use \`ansible.builtin.git\` to clone the repo directly on the webservers, \`ansible.builtin.apt\` to install git."
    inst0="Create the playbook at $playbook_dir/deploy_webapp.yml with the following content:"
    inst1="Check the playbook syntax:"
    inst2="Run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`$playbook_dir/deploy_webapp.yml\` qui clone le dépôt \`$repo_url\` directement dans \`/var/www/html\` sur le groupe d'hôtes \`webservers\` en utilisant le module \`ansible.builtin.git\`"
    hint="Utilisez \`ansible.builtin.git\` pour cloner le dépôt directement sur les webservers, \`ansible.builtin.apt\` pour installer git."
    inst0="Créez le playbook dans $playbook_dir/deploy_webapp.yml avec le contenu suivant :"
    inst1="Vérifiez la syntaxe du playbook :"
    inst2="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
---
- name: Deploy web application
  hosts: webservers
  tasks:
    - name: Ensure git is installed
      ansible.builtin.apt:
        name: git
        state: present
        update_cache: yes

    - name: Clone web application repository
      ansible.builtin.git:
        repo: "https://github.com/ansible/ansible-examples.git"
        dest: /var/www/html
        version: HEAD
        force: yes

```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/deploy_webapp.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/deploy_webapp.yml
```'

cmd_verify='```bash
curl -s -o /dev/null -w "%{http_code}" http://localhost
```'

instructions=$(jq -n \
  --arg inst0 "$inst0" --arg cmd0 "$cmd_playbook" \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_check" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst0, "command": $cmd0}, {"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

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
    "tags": "ansible,git,web-deployment"
  }'