#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/ssh_hardening.yml"

# Clean state: restore permissive SSH defaults on webservers
ansible webservers -i "$inventory" -m lineinfile \
  -a "path=/etc/ssh/sshd_config regexp='^PermitRootLogin' line='PermitRootLogin yes'" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m lineinfile \
  -a "path=/etc/ssh/sshd_config regexp='^PasswordAuthentication' line='PasswordAuthentication yes'" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m lineinfile \
  -a "path=/etc/ssh/sshd_config regexp='^ClientAliveInterval' state=absent" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m service \
  -a "name=ssh state=restarted" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: harden SSH configuration on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: disable root login
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^PermitRootLogin"
        line: "PermitRootLogin no"
        backup: yes

    - name: disable password authentication
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^PasswordAuthentication"
        line: "PasswordAuthentication no"

    - name: set client alive interval
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^ClientAliveInterval"
        line: "ClientAliveInterval 300"

    - name: restart sshd
      ansible.builtin.service:
        name: ssh
        state: restarted
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'sshd -T | grep -E \"permitrootlogin|passwordauthentication|clientaliveinterval\"' --become
\`\`\`"

case "$lang" in
  en)
    question="The security team requires **SSH hardening** on all \`webservers\`. Write a playbook at \`$pb_path\` that sets: \`PermitRootLogin no\`, \`PasswordAuthentication no\`, and \`ClientAliveInterval 300\` in \`/etc/ssh/sshd_config\`, then **restarts the SSH service**. Use the \`lineinfile\` module."
    hint="Use ansible.builtin.lineinfile with regexp to match existing directives and line to set the new value. Use backup: yes on the first task to preserve the original config. After all lineinfile tasks, add a service task to restart ssh. Verify with: sshd -T | grep -E 'permitrootlogin|passwordauthentication|clientaliveinterval'"
    inst1="Write the playbook at \`$pb_path\` — use \`lineinfile\` for each SSH directive, then restart the service:"
    inst2="Run the playbook and verify the SSH configuration on all webservers:"
    ;;
  fr)
    question="L'équipe sécurité exige le **durcissement de SSH** sur tous les \`webservers\`. Écrivez un playbook à \`$pb_path\` qui définit : \`PermitRootLogin no\`, \`PasswordAuthentication no\`, et \`ClientAliveInterval 300\` dans \`/etc/ssh/sshd_config\`, puis **redémarre le service SSH**. Utilisez le module \`lineinfile\`."
    hint="Utilisez ansible.builtin.lineinfile avec regexp pour correspondre aux directives existantes et line pour définir la nouvelle valeur. Utilisez backup: yes sur la première tâche pour préserver la config d'origine. Après toutes les tâches lineinfile, ajoutez une tâche service pour redémarrer ssh. Vérifiez avec : sshd -T | grep -E 'permitrootlogin|passwordauthentication|clientaliveinterval'"
    inst1="Écrivez le playbook à \`$pb_path\` — utilisez \`lineinfile\` pour chaque directive SSH, puis redémarrez le service :"
    inst2="Exécutez le playbook et vérifiez la configuration SSH sur tous les webservers :"
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
    "tags": "ansible,lineinfile,ssh,hardening,service,rhce"
  }'
