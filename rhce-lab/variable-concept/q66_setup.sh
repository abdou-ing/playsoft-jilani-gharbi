#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

pb_path="/home/ansible_user/workspace/copy_demo.yml"
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

# Create the source file inside the container
_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec control-node bash -c "
    mkdir -p /home/ansible_user/workspace/files
    printf 'Managed by Ansible\n' > /home/ansible_user/workspace/files/hello.txt
  "
fi

cmd1='```yaml
---
- name: copy file to webservers
  hosts: webservers
  tasks:
    - name: copy hello.txt to managed hosts
      copy:
        src: files/hello.txt
        dest: /home/ansible_user/workspace/hello.txt
        mode: "0644"
```'

cmd2='```bash
ansible-playbook -i '"$inventory_path $pb_path"'
```'

cmd3='```bash
ansible webservers -i '"$inventory_path"' -m command -a '"'"'cat /home/ansible_user/workspace/hello.txt'"'"'
```'

case "$lang" in
  en)
    question="Write a playbook at \`$pb_path\` that uses the \`copy\` module to copy \`files/hello.txt\` from the control node to \`/tmp/hello.txt\` on all \`webservers\` hosts. Run it and verify the file is present."
    hint="The copy module uses src: (path on the control node, relative to the playbook) and dest: (absolute path on the managed host). No become: needed since the destination is inside ansible_user's home directory."
    inst1="Create the playbook at <span class=\"bold-green-text\">$pb_path</span> using the <span class=\"bold-green-text\">copy</span> module — <span class=\"bold-green-text\">src:</span> is the path on the control node, <span class=\"bold-green-text\">dest:</span> is where it lands on each managed host:"
    inst2="Run the playbook to push the file to all webservers:"
    inst3="Verify the file arrived on the managed hosts at <span class=\"bold-green-text\">/home/ansible_user/workspace/hello.txt</span>:"
    ;;
  fr)
    question="Écrivez un playbook à \`$pb_path\` qui utilise le module \`copy\` pour copier \`files/hello.txt\` du nœud de contrôle vers \`/tmp/hello.txt\` sur tous les hôtes \`webservers\`. Exécutez-le et vérifiez que le fichier est présent."
    hint="Le module copy utilise src: (chemin sur le nœud de contrôle, relatif au playbook) et dest: (chemin absolu sur l'hôte géré). Pas besoin de become: car la destination est dans le répertoire personnel de ansible_user."
    inst1="Créez le playbook à <span class=\"bold-green-text\">$pb_path</span> avec le module <span class=\"bold-green-text\">copy</span> — <span class=\"bold-green-text\">src:</span> est le chemin sur le nœud de contrôle, <span class=\"bold-green-text\">dest:</span> est l'emplacement sur chaque hôte géré :"
    inst2="Exécutez le playbook pour envoyer le fichier sur tous les webservers :"
    inst3="Vérifiez que le fichier est arrivé sur les hôtes gérés à <span class=\"bold-green-text\">/home/ansible_user/workspace/hello.txt</span> :"
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
    "tags": "ansible,copy,module,playbook,files"
  }'
