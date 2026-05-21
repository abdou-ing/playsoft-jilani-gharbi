#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/cron.yml\` that runs on all hosts and creates a cron job for user \`natasha\` with: name='myname', minute='*/2', and job: \`logger \"EX294 in progress\"\`."
    hint="Use the \`cron\` module (or \`ansible.builtin.cron\`). Set \`user: natasha\` to create the cron entry for that user. The minute field must be '*/2' to run every 2 minutes."
    inst1="Create the playbook /home/ansible_user/workspace/cron.yml:"
    inst2="Run the playbook and verify the cron job:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/cron.yml\` qui s'exécute sur tous les hôtes et crée une tâche cron pour l'utilisateur \`natasha\` avec : name='myname', minute='*/2', et job: \`logger \"EX294 in progress\"\`."
    hint="Utilisez le module \`cron\` (ou \`ansible.builtin.cron\`). Définissez \`user: natasha\` pour créer l'entrée cron pour cet utilisateur. Le champ minute doit être '*/2' pour s'exécuter toutes les 2 minutes."
    inst1="Créez le playbook /home/ansible_user/workspace/cron.yml :"
    inst2="Exécutez le playbook et vérifiez la tâche cron :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Create cron job for natasha
  hosts: all
  become: true
  tasks:
    - name: Ensure natasha user exists
      ansible.builtin.user:
        name: natasha
        state: present

    - name: Create cron job for natasha
      ansible.builtin.cron:
        name: myname
        minute: "*/2"
        job: logger "EX294 in progress"
        user: natasha
        state: present
```'

cmd_verify='```bash
ansible-playbook playbooks/cron.yml
ansible all -m command -a "crontab -l -u natasha"
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_verify" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,cron,scheduler,task"}'
