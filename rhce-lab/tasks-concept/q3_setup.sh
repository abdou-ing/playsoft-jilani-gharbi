#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/when_os.yml"
inventory_path="/home/ansible_user/workspace/inventory"

# Skip-foundation guard
if [ ! -f "$inventory_path" ]; then
  mkdir -p /home/ansible_user/workspace
  printf '[webservers]\nweb1\nweb2\n\n[dbservers]\nbd1\n\n[all:vars]\nansible_user=ansible_user\n' \
    > "$inventory_path"
fi
for entry in "10.30.0.11 web1" "10.30.0.12 web2" "10.30.0.13 bd1"; do
  grep -qF "${entry%% *}" /etc/hosts 2>/dev/null || \
    printf '%s\n' "$entry" | sudo tee -a /etc/hosts >/dev/null 2>&1 || true
done
if [ ! -f "/home/ansible_user/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -b 2048 -f /home/ansible_user/.ssh/id_rsa -N "" >/dev/null 2>&1
  for _h in web1 web2 bd1; do
    SSHPASS='Labby123' sshpass -e ssh-copy-id -o StrictHostKeyChecking=no \
      -i /home/ansible_user/.ssh/id_rsa.pub ansible_user@"$_h" >/dev/null 2>&1 || true
  done
fi

cmd1='```yaml
---
- name: install nmap with os_family condition
  hosts: all
  become: yes
  tasks:
    - name: install nmap on Debian/Ubuntu hosts
      package:
        name: nmap
        state: present
      when: ansible_facts["os_family"] == "Debian"
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/when_os.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that installs \`nmap\` on \`all\` hosts, but only when \`ansible_facts['os_family'] == \"Debian\"\`. Use \`become: yes\` and run the playbook."
    hint="Add 'when: ansible_facts[\"os_family\"] == \"Debian\"' at the same indentation level as the package module — NOT inside it. Since all your hosts are Ubuntu (Debian family), nmap will be installed on every host."
    inst1="Create the playbook targeting <span class=\"bold-green-text\">hosts: all</span> with a <span class=\"bold-green-text\">when:</span> condition on the <span class=\"bold-green-text\">os_family</span> fact:"
    inst2="Run the playbook — hosts with <span class=\"bold-green-text\">os_family == Debian</span> will install nmap, others will skip the task:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui installe \`nmap\` sur \`all\` les hôtes, mais seulement quand \`ansible_facts['os_family'] == \"Debian\"\`. Utilisez \`become: yes\` et exécutez le playbook."
    hint="Ajoutez 'when: ansible_facts[\"os_family\"] == \"Debian\"' au même niveau d'indentation que le module package — PAS à l'intérieur. Comme tous vos hôtes sont Ubuntu (famille Debian), nmap sera installé sur chaque hôte."
    inst1="Créez le playbook ciblant <span class=\"bold-green-text\">hosts: all</span> avec une condition <span class=\"bold-green-text\">when:</span> sur le fact <span class=\"bold-green-text\">os_family</span> :"
    inst2="Exécutez le playbook — les hôtes avec <span class=\"bold-green-text\">os_family == Debian</span> installeront nmap, les autres passeront la tâche :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  '[
    {"instruction": $inst1, "command": $cmd1},
    {"instruction": $inst2, "command": $cmd2}
  ]')

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
    "tags": "ansible,when,os_family,facts,conditional,playbook"
  }'
