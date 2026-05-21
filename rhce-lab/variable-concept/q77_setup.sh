#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/motd.yml"

cmd1='```yaml
---
- name: set motd on all hosts
  hosts: all
  become: yes
  tasks:
    - name: write /etc/motd
      copy:
        content: "Managed by Ansible"
        dest: /etc/motd
```'
cmd2="ansible-playbook /home/ansible_user/workspace/motd.yml
ansible all -m command -a 'cat /etc/motd'"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that creates the file \`/etc/motd\` with the content \`Managed by Ansible\` on ALL hosts, then run it."
    hint="Use the copy module with content: and dest: /etc/motd. You will need become: yes since /etc/motd is owned by root. Target hosts: all."
    inst1="Create the playbook using the <span class=\"bold-green-text\">copy</span> module with <span class=\"bold-green-text\">content:</span> and <span class=\"bold-green-text\">dest: /etc/motd</span> — target <span class=\"bold-green-text\">hosts: all</span> and use <span class=\"bold-green-text\">become: yes</span>:"
    inst2="Run the playbook and verify the <span class=\"bold-green-text\">/etc/motd</span> file content on all hosts:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui crée le fichier \`/etc/motd\` avec le contenu \`Managed by Ansible\` sur TOUS les hôtes, puis exécutez-le."
    hint="Utilisez le module copy avec content: et dest: /etc/motd. Vous aurez besoin de become: yes car /etc/motd appartient à root. Ciblez hosts: all."
    inst1="Créez le playbook avec le module <span class=\"bold-green-text\">copy</span> avec <span class=\"bold-green-text\">content:</span> et <span class=\"bold-green-text\">dest: /etc/motd</span> — ciblez <span class=\"bold-green-text\">hosts: all</span> et utilisez <span class=\"bold-green-text\">become: yes</span> :"
    inst2="Exécutez le playbook et vérifiez le contenu du fichier <span class=\"bold-green-text\">/etc/motd</span> sur tous les hôtes :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n --arg inst1 "$inst1" --arg cmd1 "$cmd1" --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

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
    "tags": "ansible,copy,motd,become,playbook"
  }'
