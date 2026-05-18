#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/set_fact_vars.yml\` that uses \`set_fact\` to create a variable \`env_label\` with the value \`{{ ansible_hostname }}-prod\`, then writes that variable to \`/root/env_label.txt\` on all managed hosts using the \`copy\` module."
    hint="Use the \`set_fact\` module to define the new variable, then reference \`{{ env_label }}\` in a subsequent \`copy\` task. \`set_fact\` creates a host-level variable available for the rest of the play."
    inst1="Create the playbook at ~/playbooks/set_fact_vars.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/set_fact_vars.yml\` qui utilise \`set_fact\` pour créer une variable \`env_label\` avec la valeur \`{{ ansible_hostname }}-prod\`, puis écrit cette variable dans \`/root/env_label.txt\` sur tous les hôtes gérés en utilisant le module \`copy\`."
    hint="Utilisez le module \`set_fact\` pour définir la nouvelle variable, puis référencez \`{{ env_label }}\` dans une tâche \`copy\` suivante. \`set_fact\` crée une variable au niveau de l'hôte disponible pour le reste du play."
    inst1="Créez le playbook dans ~/playbooks/set_fact_vars.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Compute a variable with set_fact
  hosts: all
  become: true
  tasks:
    - name: Build env_label variable
      set_fact:
        env_label: "{{ ansible_hostname }}-prod"

    - name: Write env_label to file
      copy:
        dest: /root/env_label.txt
        content: "{{ env_label }}\n"
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/set_fact_vars.yml
ansible-playbook playbooks/set_fact_vars.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,set_fact,variables,copy"}'
