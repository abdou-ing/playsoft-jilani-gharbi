#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/ip_forwarding.yml"
sysctl_file="/etc/sysctl.d/99-forwarding.conf"

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

# Clean state: remove sysctl forwarding config from webservers
ansible webservers -i "$inventory" -m file \
  -a "path=$sysctl_file state=absent" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m command \
  -a "sysctl -w net.ipv4.ip_forward=0" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: enable IP forwarding on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: create sysctl config for IP forwarding
      ansible.builtin.lineinfile:
        path: /etc/sysctl.d/99-forwarding.conf
        line: "net.ipv4.ip_forward = 1"
        create: yes

    - name: apply sysctl settings
      ansible.builtin.command:
        cmd: sysctl -p /etc/sysctl.d/99-forwarding.conf
      changed_when: true
```'
cmd2="ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'sysctl net.ipv4.ip_forward' --become"

case "$lang" in
  en)
    question="The webservers need to route traffic between network segments. Write a playbook at \`$pb_path\` that enables IP forwarding on all \`webservers\` by creating \`/etc/sysctl.d/99-forwarding.conf\` with \`net.ipv4.ip_forward = 1\` using \`lineinfile\` (with \`create: yes\`), then applies the setting with \`sysctl -p\`."
    hint="Use ansible.builtin.lineinfile with create: yes to create the file if it doesn't exist. Then use ansible.builtin.command with cmd: sysctl -p /etc/sysctl.d/99-forwarding.conf and changed_when: true to apply the kernel parameter immediately. Verify: ansible webservers -m command -a 'sysctl net.ipv4.ip_forward' --become"
    inst1="Write the playbook — create the sysctl config with <span class=\"bold-green-text\">lineinfile</span> (create: yes), then apply with <span class=\"bold-green-text\">sysctl -p</span>:"
    inst2="Run the playbook and verify IP forwarding is enabled on all webservers:"
    ;;
  fr)
    question="Les webservers doivent router le trafic entre les segments réseau. Écrivez un playbook à \`$pb_path\` qui active le forwarding IP sur tous les \`webservers\` en créant \`/etc/sysctl.d/99-forwarding.conf\` avec \`net.ipv4.ip_forward = 1\` via \`lineinfile\` (avec \`create: yes\`), puis applique le paramètre avec \`sysctl -p\`."
    hint="Utilisez ansible.builtin.lineinfile avec create: yes pour créer le fichier s'il n'existe pas. Ensuite utilisez ansible.builtin.command avec cmd: sysctl -p /etc/sysctl.d/99-forwarding.conf et changed_when: true pour appliquer le paramètre kernel immédiatement. Vérifiez : ansible webservers -m command -a 'sysctl net.ipv4.ip_forward' --become"
    inst1="Écrivez le playbook — créez la config sysctl avec <span class=\"bold-green-text\">lineinfile</span> (create: yes), puis appliquez avec <span class=\"bold-green-text\">sysctl -p</span> :"
    inst2="Exécutez le playbook et vérifiez que le forwarding IP est activé sur tous les webservers :"
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
    "tags": "ansible,lineinfile,sysctl,ip-forwarding,kernel,rhce"
  }'
