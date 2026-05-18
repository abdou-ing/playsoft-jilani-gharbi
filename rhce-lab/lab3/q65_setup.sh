#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/register_vars.yml\` that runs the command \`hostname -s\` on all managed hosts, captures the output using \`register: host_result\`, and writes the result to \`/root/registered_hostname.txt\` using the \`copy\` module with \`content: \"{{ host_result.stdout }}\n\"\`."
    hint="Use the \`command\` module to run \`hostname -s\` and capture its output with \`register:\`. Then use the \`copy\` module with \`content:\` to write \`{{ host_result.stdout }}\` to the file."
    inst1="Create the playbook at ~/playbooks/register_vars.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/register_vars.yml\` qui exécute la commande \`hostname -s\` sur tous les hôtes gérés, capture la sortie avec \`register: host_result\`, et écrit le résultat dans \`/root/registered_hostname.txt\` en utilisant le module \`copy\` avec \`content: \"{{ host_result.stdout }}\n\"\`."
    hint="Utilisez le module \`command\` pour exécuter \`hostname -s\` et capturer sa sortie avec \`register:\`. Utilisez ensuite le module \`copy\` avec \`content:\` pour écrire \`{{ host_result.stdout }}\` dans le fichier."
    inst1="Créez le playbook dans ~/playbooks/register_vars.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Register command output to a variable
  hosts: all
  become: true
  tasks:
    - name: Get hostname
      command: hostname -s
      register: host_result

    - name: Write registered output to file
      copy:
        dest: /root/registered_hostname.txt
        content: "{{ host_result.stdout }}\n"
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/register_vars.yml
ansible-playbook playbooks/register_vars.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,register,variables,copy"}'
