#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory_path="/home/ansible_user/workspace/inventory"

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec control-node bash -c '
    rm -f /home/ansible_user/.ssh/id_rsa /home/ansible_user/.ssh/id_rsa.pub
  '
fi

cmd1='```bash
sudo tee -a /etc/hosts << '"'"'EOF'"'"'
10.30.0.11 web1
10.30.0.12 web2
10.30.0.13 bd1
EOF
```'

cmd2='```bash
mkdir -p ~/workspace
cat > ~/workspace/inventory << '"'"'EOF'"'"'
[webservers]
web1
web2

[dbservers]
bd1

[all:vars]
ansible_user=ansible_user
EOF
```'

cmd3='```bash
ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
```'

cmd4='```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub ansible_user@web1
ssh-copy-id -i ~/.ssh/id_rsa.pub ansible_user@web2
ssh-copy-id -i ~/.ssh/id_rsa.pub ansible_user@bd1
```'

cmd5='```bash
ansible -i ~/workspace/inventory all -m ping
```'

case "$lang" in
  en)
    question="Configure Ansible to manage three hosts — web1 (10.30.0.11), web2 (10.30.0.12), and bd1 (10.30.0.13). Set up SSH key-based authentication for ansible_user on each host, then verify that Ansible can reach all of them."
    hint="The ansible_user password on each managed host is: Labby123. Work through the steps in order: /etc/hosts → inventory → ssh-keygen → ssh-copy-id × 3 → ansible ping."
    inst1="Add the managed host entries to <span class=\"bold-green-text\">/etc/hosts</span> so they are reachable by hostname:"
    inst2="Create the Ansible <span class=\"bold-green-text\">inventory file</span> at <span class=\"bold-green-text\">~/workspace/inventory</span> grouping webservers and dbservers:"
    inst3="Generate an <span class=\"bold-green-text\">SSH key pair</span> for the ansible_user account (no passphrase):"
    inst4="Distribute the public key to each managed host with <span class=\"bold-green-text\">ssh-copy-id</span> — when prompted, enter the password <span class=\"bold-green-text\">Labby123</span>:"
    inst5="Test Ansible connectivity to all hosts using the <span class=\"bold-green-text\">ping</span> module — every host must return <span class=\"bold-green-text\">SUCCESS</span>:"
    ;;
  fr)
    question="Configurez Ansible pour gérer trois hôtes — web1 (10.30.0.11), web2 (10.30.0.12) et bd1 (10.30.0.13). Mettez en place l'authentification par clé SSH pour ansible_user sur chaque hôte, puis vérifiez qu'Ansible peut les joindre tous."
    hint="Le mot de passe de ansible_user sur chaque hôte géré est : Labby123. Suivez les étapes dans l'ordre : /etc/hosts → inventaire → ssh-keygen → ssh-copy-id × 3 → ansible ping."
    inst1="Ajoutez les entrées des hôtes gérés dans <span class=\"bold-green-text\">/etc/hosts</span> pour qu'ils soient accessibles par nom d'hôte :"
    inst2="Créez le <span class=\"bold-green-text\">fichier d'inventaire</span> Ansible à <span class=\"bold-green-text\">~/workspace/inventory</span> en regroupant les webservers et dbservers :"
    inst3="Générez une <span class=\"bold-green-text\">paire de clés SSH</span> pour le compte ansible_user (sans phrase secrète) :"
    inst4="Distribuez la clé publique sur chaque hôte géré avec <span class=\"bold-green-text\">ssh-copy-id</span> — entrez le mot de passe <span class=\"bold-green-text\">Labby123</span> quand demandé :"
    inst5="Testez la connectivité Ansible sur tous les hôtes avec le module <span class=\"bold-green-text\">ping</span> — chaque hôte doit retourner <span class=\"bold-green-text\">SUCCESS</span> :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd1" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd3" \
  --arg inst4 "$inst4" --arg cmd4 "$cmd4" \
  --arg inst5 "$inst5" --arg cmd5 "$cmd5" \
  '[
    {"instruction": $inst1, "command": $cmd1},
    {"instruction": $inst2, "command": $cmd2},
    {"instruction": $inst3, "command": $cmd3},
    {"instruction": $inst4, "command": $cmd4},
    {"instruction": $inst5, "command": $cmd5}
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
    "tags": "ansible,ssh,inventory,ping,connectivity"
  }'
