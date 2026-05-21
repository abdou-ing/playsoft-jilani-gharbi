#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/install_pkg.yml"
inventory_path="/home/ansible_user/workspace/inventory"

# Skip-q60 guard: ensure inventory, /etc/hosts and SSH keys are ready
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
- name: install a package
  hosts: all
  vars:
    pkg_name: curl
  tasks:
    - name: install package
      package:
        name: {{ pkg_name }}
        state: present
```'

cmd2='```yaml
---
- name: install a package
  hosts: all
  vars:
    pkg_name: curl
  tasks:
    - name: install package
      package:
        name: "{{ pkg_name }}"
        state: present
```'

cmd3="ansible-playbook -i /home/ansible_user/workspace/inventory /home/ansible_user/workspace/install_pkg.yml"

case "$lang" in
  en)
    question="The playbook below has a YAML syntax error. Fix it and save the corrected version at \`$pb_path\`, then run it to install \`curl\` on all hosts."
    hint="YAML treats any value starting with {{ as a dictionary literal and raises a parse error. Wrap the variable reference in double quotes: name: \"{{ pkg_name }}\""
    inst1="Spot the error — YAML cannot parse a bare <span class=\"bold-green-text\">{{ }}</span> at the start of a value. Here is the broken playbook:"
    inst2="Write the fixed playbook at <span class=\"bold-green-text\">$pb_path</span> — the only change is wrapping the variable reference in <span class=\"bold-green-text\">double quotes</span>:"
    inst3="Run the playbook to install the package on all hosts:"
    ;;
  fr)
    question="Le playbook ci-dessous contient une erreur de syntaxe YAML. Corrigez-le et sauvegardez la version corrigée à \`$pb_path\`, puis exécutez-le pour installer \`curl\` sur tous les hôtes."
    hint="YAML traite toute valeur commençant par {{ comme un dictionnaire littéral et lève une erreur d'analyse. Encadrez la référence de variable avec des guillemets doubles : name: \"{{ pkg_name }}\""
    inst1="Repérez l'erreur — YAML ne peut pas analyser un <span class=\"bold-green-text\">{{ }}</span> nu en début de valeur. Voici le playbook cassé :"
    inst2="Écrivez le playbook corrigé à <span class=\"bold-green-text\">$pb_path</span> — le seul changement est d'encadrer la référence de variable avec des <span class=\"bold-green-text\">guillemets doubles</span> :"
    inst3="Exécutez le playbook pour installer le paquet sur tous les hôtes :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd3" \
  '[
    {"instruction": $inst1, "command": $cmd1},
    {"instruction": $inst2, "command": $cmd2},
    {"instruction": $inst3, "command": $cmd3}
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
    "tags": "ansible,yaml,variables,quoting,playbook"
  }'
