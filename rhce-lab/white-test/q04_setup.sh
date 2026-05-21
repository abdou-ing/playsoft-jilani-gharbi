#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/timesync.yml\` that runs on all hosts, installs the \`chrony\` package, deploys \`/etc/chrony.conf\` with \`server pool.ntp.org iburst\`, and ensures the \`chrony\` service is enabled and started."
    hint="Use the \`template\` or \`copy\` module for chrony.conf. Use the \`service\` module with \`state: started\` and \`enabled: true\` for the chrony service."
    inst1="Create the playbook /home/ansible_user/workspace/timesync.yml:"
    inst2="Check syntax and run the playbook:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/timesync.yml\` qui s'exécute sur tous les hôtes, installe le paquet \`chrony\`, déploie \`/etc/chrony.conf\` avec \`server pool.ntp.org iburst\`, et assure que le service \`chrony\` est activé et démarré."
    hint="Utilisez le module \`template\` ou \`copy\` pour chrony.conf. Utilisez le module \`service\` avec \`state: started\` et \`enabled: true\` pour le service chrony."
    inst1="Créez le playbook /home/ansible_user/workspace/timesync.yml :"
    inst2="Vérifiez la syntaxe et exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Configure time synchronization with chrony
  hosts: all
  become: true
  tasks:
    - name: Install chrony
      ansible.builtin.apt:
        name: chrony
        state: present
        update_cache: true

    - name: Deploy /etc/chrony.conf
      ansible.builtin.copy:
        content: |
          server pool.ntp.org iburst
        dest: /etc/chrony.conf
        owner: root
        group: root
        mode: "0644"
      notify: Restart chrony

    - name: Enable and start chrony service
      ansible.builtin.service:
        name: chrony
        state: started
        enabled: true

  handlers:
    - name: Restart chrony
      ansible.builtin.service:
        name: chrony
        state: restarted
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/timesync.yml
ansible-playbook playbooks/timesync.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,chrony,timesync,service"}'
