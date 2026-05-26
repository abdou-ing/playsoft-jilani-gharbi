#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/account_expiry.yml"

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

# Clean state: remove account expiry from john on webservers
ansible webservers -i "$inventory" -m command \
  -a "chage -E -1 john" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: set account expiry for john on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: set account expiry date
      ansible.builtin.command:
        cmd: chage -E 2026-12-31 john
      changed_when: true
```'
cmd2="ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'chage -l john' --become"

case "$lang" in
  en)
    question="HR has informed you that john's contract ends on \`2026-12-31\`. Write a playbook at \`$pb_path\` that sets john's account expiry date to \`2026-12-31\` on all \`webservers\` using the \`command\` module with \`chage -E\`. Run it and verify."
    hint="Use ansible.builtin.command with cmd: chage -E 2026-12-31 john and become: yes. Add changed_when: true since chage produces no detectable output. Verify with: ansible webservers -m command -a 'chage -l john' --become and look for 'Account expires' field."
    inst1="Write the playbook using the <span class=\"bold-green-text\">command</span> module to set the account expiry with <span class=\"bold-green-text\">chage -E</span>:"
    inst2="Run the playbook and verify the expiry date is set on all webservers:"
    ;;
  fr)
    question="Les RH vous informent que le contrat de john se termine le \`2026-12-31\`. Écrivez un playbook à \`$pb_path\` qui définit la date d'expiration du compte de john au \`2026-12-31\` sur tous les \`webservers\` via le module \`command\` avec \`chage -E\`. Exécutez-le et vérifiez."
    hint="Utilisez ansible.builtin.command avec cmd: chage -E 2026-12-31 john et become: yes. Ajoutez changed_when: true car chage ne produit pas de sortie détectable. Vérifiez avec : ansible webservers -m command -a 'chage -l john' --become et cherchez le champ 'Account expires'."
    inst1="Écrivez le playbook avec le module <span class=\"bold-green-text\">command</span> pour définir l'expiration du compte avec <span class=\"bold-green-text\">chage -E</span> :"
    inst2="Exécutez le playbook et vérifiez que la date d'expiration est définie sur tous les webservers :"
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
    "tags": "ansible,command,chage,account-expiry,rhce"
  }'
