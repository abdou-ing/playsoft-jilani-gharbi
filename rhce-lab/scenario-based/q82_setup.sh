#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/password_policy.yml"

# Skip-q60 guard
if [ ! -f "$inventory" ]; then
  mkdir -p /home/ansible_user/workspace
  printf '[webservers]\nweb1\nweb2\n\n[dbservers]\nbd1\n\n[all:vars]\nansible_user=ansible_user\n' > "$inventory"
fi
for entry in "10.30.0.11 web1" "10.30.0.12 web2" "10.30.0.13 bd1"; do
  grep -qF "${entry%% *}" /etc/hosts 2>/dev/null || printf '%s\n' "$entry" | sudo tee -a /etc/hosts >/dev/null 2>&1 || true
done
if [ ! -f "/home/ansible_user/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -b 2048 -f /home/ansible_user/.ssh/id_rsa -N "" >/dev/null 2>&1
  for _h in web1 web2 bd1; do
    SSHPASS='Labby123' sshpass -e ssh-copy-id -o StrictHostKeyChecking=no \
      -i /home/ansible_user/.ssh/id_rsa.pub ansible_user@"$_h" >/dev/null 2>&1 || true
  done
fi

# Skip-q78 guard: ensure john exists
ansible webservers -i "$inventory" -m user \
  -a "name=john create_home=yes shell=/bin/bash state=present" \
  --become -o >/dev/null 2>&1 || true

# Clean state: reset password aging to defaults on webservers
ansible webservers -i "$inventory" -m command \
  -a "chage -M 99999 -W 7 john" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: enforce password policy for john on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: set password max age and warning period
      ansible.builtin.command:
        cmd: chage -M 90 -W 7 john
      changed_when: true
```'
cmd2="ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'chage -l john' --become"

case "$lang" in
  en)
    question="Security policy requires that john's password expires every \`90\` days with a \`7\`-day warning on all webservers. Write a playbook at \`$pb_path\` that enforces this using \`chage\` via the \`command\` module. Run it and verify the policy is applied."
    hint="Use ansible.builtin.command with cmd: chage -M 90 -W 7 john and become: yes. Add changed_when: true since chage does not produce output that Ansible can detect as a change. Verify with: ansible webservers -m command -a 'chage -l john' --become"
    inst1="Write the playbook using the <span class=\"bold-green-text\">command</span> module to run <span class=\"bold-green-text\">chage</span> on each webserver:"
    inst2="Run the playbook and verify the password aging policy is applied on all webservers:"
    ;;
  fr)
    question="La politique de sécurité exige que le mot de passe de john expire tous les \`90\` jours avec un avertissement de \`7\` jours sur tous les webservers. Écrivez un playbook à \`$pb_path\` qui applique cela avec \`chage\` via le module \`command\`. Exécutez-le et vérifiez."
    hint="Utilisez ansible.builtin.command avec cmd: chage -M 90 -W 7 john et become: yes. Ajoutez changed_when: true car chage ne produit pas de sortie qu'Ansible peut détecter comme un changement. Vérifiez avec : ansible webservers -m command -a 'chage -l john' --become"
    inst1="Écrivez le playbook avec le module <span class=\"bold-green-text\">command</span> pour exécuter <span class=\"bold-green-text\">chage</span> sur chaque webserver :"
    inst2="Exécutez le playbook et vérifiez que la politique de vieillissement du mot de passe est appliquée sur tous les webservers :"
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
    "tags": "ansible,command,chage,password-policy,rhce"
  }'
