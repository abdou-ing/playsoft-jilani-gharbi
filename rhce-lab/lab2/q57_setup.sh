#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Write an Ansible playbook at \`/home/ansible_user/playbooks/copy_file.yml\` that creates the directory \`/etc/myapp\` and copies the file \`config.json\` (already present in \`/home/ansible_user/playbooks/\`) to \`/etc/myapp/\` on all managed hosts."
    hint="Use the \`ansible.builtin.file\` module to create the directory and the \`ansible.builtin.copy\` module for the file. The \`src\` path is relative to the playbook location."
    inst1="The file config.json is already prepared in /home/ansible_user/playbooks/. Create the playbook at /home/ansible_user/playbooks/copy_file.yml:"
    inst2="Check the playbook syntax:"
    inst3="Run the playbook:"
    ;;
  fr)
    question="Écrivez un playbook Ansible dans \`/home/ansible_user/playbooks/copy_file.yml\` qui crée le répertoire \`/etc/myapp\` et copie le fichier \`config.json\` (déjà présent dans \`/home/ansible_user/playbooks/\`) vers \`/etc/myapp/\` sur toutes les machines hôtes."
    hint="Utilisez le module \`ansible.builtin.file\` pour créer le répertoire et le module \`ansible.builtin.copy\` pour le fichier. Le chemin \`src\` est relatif à l'emplacement du playbook."
    inst1="Le fichier config.json est déjà préparé dans /home/ansible_user/playbooks/. Créez le playbook dans /home/ansible_user/playbooks/copy_file.yml :"
    inst2="Vérifiez la syntaxe du playbook :"
    inst3="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cat > /home/ansible_user/playbooks/config.json << 'EOF'
{
  "app_name": "myapp",
  "version": "1.0.0",
  "environment": "production",
  "debug": false,
  "database": {
    "host": "localhost",
    "port": 5432,
    "name": "myapp_db",
    "user": "myapp_user",
    "password": "changeme"
  },
  "api": {
    "endpoint": "https://api.example.com",
    "timeout": 30,
    "retries": 3
  },
  "logging": {
    "level": "info",
    "file": "/var/log/myapp/app.log",
    "max_size_mb": 100
  },
  "features": {
    "enable_cache": true,
    "enable_metrics": false,
    "rate_limit": 1000
  },
  "security": {
    "ssl_enabled": true,
    "session_timeout": 3600,
    "encryption_key": "change-this-in-production"
  }
}
EOF

cmd_playbook='```yaml
- name: Copy config.json to /etc/myapp
  hosts: all
  become: true
  tasks:
    - name: Create /etc/myapp directory
      ansible.builtin.file:
        path: /etc/myapp
        state: directory
    - name: Copy config.json
      ansible.builtin.copy:
        src: config.json
        dest: /etc/myapp/
```'

cmd_check='```bash
ansible-playbook --syntax-check /home/ansible_user/playbooks/copy_file.yml
```'

cmd_run='```bash
ansible-playbook /home/ansible_user/playbooks/copy_file.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,copy,file"}'
