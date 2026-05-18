#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/vars_motd.yml\` that writes a Message of the Day to \`/etc/motd\` on all managed hosts. The playbook must use a \`vars\` section with a variable \`company_name\` set to \`PlaySoft\`. The file content must include the actual hostname (via \`ansible_hostname\`) and the company name (via \`{{ company_name }}\`)."
    hint="Use the \`copy\` module with the \`content\` parameter and Jinja2 templating to combine the fact and the variable in the file content."
    inst1="Create the playbook at ~/playbooks/vars_motd.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/vars_motd.yml\` qui écrit un Message du Jour dans \`/etc/motd\` sur tous les hôtes gérés. Le playbook doit utiliser une section \`vars\` avec une variable \`company_name\` définie à \`PlaySoft\`. Le contenu du fichier doit inclure le nom d'hôte réel (via \`ansible_hostname\`) et le nom de la société (via \`{{ company_name }}\`)."
    hint="Utilisez le module \`copy\` avec le paramètre \`content\` et le templating Jinja2 pour combiner le fact et la variable dans le contenu du fichier."
    inst1="Créez le playbook dans ~/playbooks/vars_motd.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Write Message of the Day
  hosts: all
  become: true
  vars:
    company_name: "PlaySoft"
  tasks:
    - name: Write /etc/motd with hostname and company name
      copy:
        dest: /etc/motd
        content: |
          Welcome to {{ ansible_hostname }}
          Managed by {{ company_name }}
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/vars_motd.yml
ansible-playbook playbooks/vars_motd.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,vars,variables,copy,motd"}'
