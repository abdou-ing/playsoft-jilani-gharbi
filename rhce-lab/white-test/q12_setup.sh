#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/issue.yml\` that runs on all hosts and sets \`/etc/issue\` based on group membership: hosts in \`dev\` group get 'Development', hosts in \`test\` get 'Test', hosts in \`prod\` get 'Production'. Use \`when\` conditions with \`inventory_hostname in groups[...]\`."
    hint="Use three separate copy tasks, each with a \`when\` condition. Note: since web1 is in both dev and prod, the last matching task wins (web1 ends up as 'Production'). Similarly web2 ends up as 'Production'."
    inst1="Create the playbook /home/ansible_user/workspace/issue.yml:"
    inst2="Run the playbook and verify:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/issue.yml\` qui s'exécute sur tous les hôtes et définit \`/etc/issue\` selon l'appartenance au groupe : les hôtes du groupe \`dev\` reçoivent 'Development', \`test\` reçoit 'Test', \`prod\` reçoit 'Production'. Utilisez des conditions \`when\` avec \`inventory_hostname in groups[...]\`."
    hint="Utilisez trois tâches copy séparées, chacune avec une condition \`when\`. Note : comme web1 est dans dev et prod, la dernière tâche correspondante l'emporte (web1 finit avec 'Production'). De même web2 finit avec 'Production'."
    inst1="Créez le playbook /home/ansible_user/workspace/issue.yml :"
    inst2="Exécutez le playbook et vérifiez :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Set /etc/issue based on group membership
  hosts: all
  become: true
  tasks:
    - name: Set /etc/issue for dev group
      ansible.builtin.copy:
        content: "Development\n"
        dest: /etc/issue
      when: inventory_hostname in groups["dev"]

    - name: Set /etc/issue for test group
      ansible.builtin.copy:
        content: "Test\n"
        dest: /etc/issue
      when: inventory_hostname in groups["test"]

    - name: Set /etc/issue for prod group
      ansible.builtin.copy:
        content: "Production\n"
        dest: /etc/issue
      when: inventory_hostname in groups["prod"]
```'

cmd_run='```bash
ansible-playbook playbooks/issue.yml
ansible all -m command -a "cat /etc/issue"
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,when,groups,copy"}'
