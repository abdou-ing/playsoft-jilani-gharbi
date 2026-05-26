#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/loop_when.yml"
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
- name: install packages with loop and when
  hosts: webservers
  become: yes
  tasks:
    - name: install package only on Ubuntu/Debian
      package:
        name: "{{ item }}"
        state: present
      loop:
        - vim
        - wget
        - git
      when: ansible_facts["distribution"] in ["Ubuntu", "Debian"]
```'
cmd2="ansible-playbook -i ~/workspace/inventory ~/workspace/loop_when.yml"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that combines \`loop\` and \`when\` to install the packages \`vim\`, \`wget\`, and \`git\` on \`webservers\`, but only when \`ansible_facts['distribution']\` is \`Ubuntu\` or \`Debian\`. Run the playbook."
    hint="Both 'loop:' and 'when:' apply at the same indentation level as the module. When used together, the 'when:' is evaluated for every iteration of the loop. Use: when: ansible_facts['distribution'] in [\"Ubuntu\", \"Debian\"]"
    inst1="Create the playbook combining <span class=\"bold-green-text\">loop:</span> and <span class=\"bold-green-text\">when:</span> — the condition is evaluated on each loop iteration:"
    inst2="Run the playbook — packages install only on Ubuntu/Debian hosts, others skip each item:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui combine \`loop\` et \`when\` pour installer les paquets \`vim\`, \`wget\` et \`git\` sur \`webservers\`, mais uniquement quand \`ansible_facts['distribution']\` est \`Ubuntu\` ou \`Debian\`. Exécutez le playbook."
    hint="'loop:' et 'when:' s'appliquent tous deux au même niveau d'indentation que le module. Utilisés ensemble, 'when:' est évalué à chaque itération. Utilisez : when: ansible_facts['distribution'] in [\"Ubuntu\", \"Debian\"]"
    inst1="Créez le playbook combinant <span class=\"bold-green-text\">loop:</span> et <span class=\"bold-green-text\">when:</span> — la condition est évaluée à chaque itération :"
    inst2="Exécutez le playbook — les paquets s'installent uniquement sur les hôtes Ubuntu/Debian, les autres passent :"
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
    "tags": "ansible,loop,when,distribution,conditional,package"
  }'
