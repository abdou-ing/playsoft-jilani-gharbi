#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="update playbook at \`/home/ansible_user/playbooks/webserver.yml\` in order to make apache2 started across reboot"
    hint="Use the \`ansible.builtin.systemd_service\` module to enable/start service."
    inst1="Create the playbook at /home/ansible_user/playbooks/webserver.yml:"
    inst2="Check the playbook syntax:"
    inst3="Run the playbook:"
    ;;

  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Install apache2 on webservers
  hosts: webservers
  become: true
  tasks:

    - name: Make sure apache service unit is running and enabled
      ansible.builtin.systemd_serviceservice:
        state: started
        enabled: true
        name: apache2
      
```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/webserver.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/webserver.yml
```'

# Handle the case user skipped the installation of apache
ansible webservers -m apt -a "name=apache2 state=present update_cache: yes" -b >/dev/null 2>&1

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,apache2,vim"}'
