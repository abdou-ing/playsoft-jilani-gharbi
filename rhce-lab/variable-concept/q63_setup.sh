#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/facts_demo.yml"
inventory_path="/home/ansible_user/workspace/inventory"

# Skip-q60 guard
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
- name: display OS distribution
  hosts: all
  gather_facts: no
  tasks:
    - name: show distribution
      debug:
        msg: "OS is {{ ansible_facts['"'"'distribution'"'"'] }}"
```'

cmd2='```yaml
---
- name: display OS distribution
  hosts: all
  tasks:
    - name: show distribution
      debug:
        msg: "OS is {{ ansible_facts['"'"'distribution'"'"'] }}"
```'

cmd3="ansible-playbook -i $inventory_path $pb_path"

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that displays the OS distribution of all managed hosts using \`ansible_facts['distribution']\` and the \`debug\` module. The playbook must actually show the value — not \`VARIABLE IS NOT DEFINED\`. Run it."
    hint="gather_facts: yes is the default — do not add gather_facts: no or facts will be empty. ansible_facts['distribution'] is populated automatically when Ansible connects to each host."
    inst1="The broken version below uses <span class=\"bold-green-text\">gather_facts: no</span>, which empties ansible_facts — the debug output will show VARIABLE IS NOT DEFINED:"
    inst2="The fix is simple: remove <span class=\"bold-green-text\">gather_facts: no</span> (or omit it entirely). Ansible collects facts by default before running any task:"
    inst3="Run the playbook — each host should display its OS distribution (e.g. <span class=\"bold-green-text\">Ubuntu</span>):"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui affiche la distribution OS de tous les hôtes gérés en utilisant \`ansible_facts['distribution']\` et le module \`debug\`. Le playbook doit vraiment afficher la valeur — pas \`VARIABLE IS NOT DEFINED\`. Exécutez-le."
    hint="gather_facts: yes est la valeur par défaut — n'ajoutez pas gather_facts: no ou les faits seront vides. ansible_facts['distribution'] est rempli automatiquement quand Ansible se connecte à chaque hôte."
    inst1="La version cassée ci-dessous utilise <span class=\"bold-green-text\">gather_facts: no</span>, ce qui vide ansible_facts — la sortie debug affichera VARIABLE IS NOT DEFINED :"
    inst2="La correction est simple : supprimez <span class=\"bold-green-text\">gather_facts: no</span> (ou omettez-le). Ansible collecte les faits par défaut avant d'exécuter toute tâche :"
    inst3="Exécutez le playbook — chaque hôte doit afficher sa distribution OS (ex. <span class=\"bold-green-text\">Ubuntu</span>) :"
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
    "tags": "ansible,facts,gather_facts,debug,playbook"
  }'
