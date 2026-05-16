#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`~/playbooks/copy_file.yml\` that creates the directory \`/etc/myapp\` and copies the file \`config.json\` (already present in \`~/playbooks/\`) to \`/etc/myapp/\` on all managed hosts."
    hint="Use the \`file\` module to create the directory and the \`copy\` module for the file. The \`src\` path is relative to the playbook location."
    inst1="The file config.json is already prepared in ~/playbooks/. Create the playbook at ~/playbooks/copy_file.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`~/playbooks/copy_file.yml\` qui crée le répertoire \`/etc/myapp\` et copie le fichier \`config.json\` (déjà présent dans \`~/playbooks/\`) vers \`/etc/myapp/\` sur toutes les machines hôtes."
    hint="Utilisez le module \`file\` pour créer le répertoire et le module \`copy\` pour le fichier. Le chemin \`src\` est relatif à l'emplacement du playbook."
    inst1="Le fichier config.json est déjà préparé dans ~/playbooks/. Créez le playbook dans ~/playbooks/copy_file.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Copy config.json to /etc/myapp
  hosts: all
  become: true
  tasks:
    - name: Create /etc/myapp directory
      file:
        path: /etc/myapp
        state: directory
    - name: Copy config.json
      copy:
        src: config.json
        dest: /etc/myapp/
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/copy_file.yml
ansible-playbook playbooks/copy_file.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,copy,file"}'
