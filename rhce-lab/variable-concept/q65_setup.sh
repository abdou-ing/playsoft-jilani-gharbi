#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

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

# Remove any existing all_servers:children block so the task is clean each run
sed -i '/^\[all_servers:children\]/,/^$/d' "$inventory_path" 2>/dev/null || true

cmd1='```bash
cat '"$inventory_path"'
```'

cmd2='```ini
[all_servers:children]
webservers
dbservers
```'

cmd3='```bash
ansible all_servers --list-hosts -i '"$inventory_path"'
```'

case "$lang" in
  en)
    question="Your inventory at \`$inventory_path\` already has a \`[webservers]\` group (web1, web2) and a \`[dbservers]\` group (bd1). Add a parent group called \`all_servers\` using the \`[all_servers:children]\` syntax so it contains both groups. Verify that \`ansible all_servers --list-hosts\` returns all 3 hosts."
    hint="Use the :children suffix to declare that the members of a group are other groups, not individual hosts. Append [all_servers:children] followed by webservers and dbservers to your inventory file."
    inst1="Inspect the current inventory to see the existing groups <span class=\"bold-green-text\">webservers</span> and <span class=\"bold-green-text\">dbservers</span>:"
    inst2="Append the <span class=\"bold-green-text\">[all_servers:children]</span> block to your inventory — list the child group names, not the hosts directly:"
    inst3="Verify that <span class=\"bold-green-text\">all_servers</span> now resolves to all 3 hosts (web1, web2, bd1):"
    ;;
  fr)
    question="Votre inventaire à \`$inventory_path\` possède déjà un groupe \`[webservers]\` (web1, web2) et un groupe \`[dbservers]\` (bd1). Ajoutez un groupe parent appelé \`all_servers\` avec la syntaxe \`[all_servers:children]\` pour qu'il contienne les deux groupes. Vérifiez que \`ansible all_servers --list-hosts\` retourne les 3 hôtes."
    hint="Utilisez le suffixe :children pour déclarer que les membres d'un groupe sont d'autres groupes, pas des hôtes individuels. Ajoutez [all_servers:children] suivi de webservers et dbservers à votre fichier d'inventaire."
    inst1="Inspectez l'inventaire actuel pour voir les groupes existants <span class=\"bold-green-text\">webservers</span> et <span class=\"bold-green-text\">dbservers</span> :"
    inst2="Ajoutez le bloc <span class=\"bold-green-text\">[all_servers:children]</span> à votre inventaire — listez les noms des groupes enfants, pas les hôtes directement :"
    inst3="Vérifiez que <span class=\"bold-green-text\">all_servers</span> résout maintenant vers les 3 hôtes (web1, web2, bd1) :"
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
    "tags": "ansible,inventory,children,groups"
  }'
