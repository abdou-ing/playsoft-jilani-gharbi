#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/web.yml\` that runs on the \`dev\` group and: creates group \`webdev\`; creates directory \`/webdev\` with mode 02775, group webdev, owner www-data; creates a symlink from \`/webdev\` to \`/var/www/html/mywebdev\`; creates \`/webdev/index.html\` with content 'Development', mode 0640, owned by www-data."
    hint="Use the \`group\` module, \`file\` module (with \`setgid\` via mode 02775), and \`copy\` module. The symlink uses \`state: link\`, \`src: /webdev\`, \`path: /var/www/html/mywebdev\`."
    inst1="Create the playbook /home/ansible_user/workspace/web.yml:"
    inst2="Check syntax and run the playbook:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/web.yml\` qui s'exécute sur le groupe \`dev\` et : crée le groupe \`webdev\` ; crée le répertoire \`/webdev\` avec le mode 02775, groupe webdev, propriétaire www-data ; crée un lien symbolique de \`/webdev\` vers \`/var/www/html/mywebdev\` ; crée \`/webdev/index.html\` avec le contenu 'Development', mode 0640, appartenant à www-data."
    hint="Utilisez le module \`group\`, le module \`file\` (avec le bit setgid via le mode 02775), et le module \`copy\`. Le lien symbolique utilise \`state: link\`, \`src: /webdev\`, \`path: /var/www/html/mywebdev\`."
    inst1="Créez le playbook /home/ansible_user/workspace/web.yml :"
    inst2="Vérifiez la syntaxe et exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Configure web development directory
  hosts: dev
  become: true
  tasks:
    - name: Create webdev group
      ansible.builtin.group:
        name: webdev
        state: present

    - name: Create /webdev directory
      ansible.builtin.file:
        path: /webdev
        state: directory
        mode: "02775"
        owner: www-data
        group: webdev

    - name: Create symlink /var/www/html/mywebdev -> /webdev
      ansible.builtin.file:
        src: /webdev
        path: /var/www/html/mywebdev
        state: link

    - name: Create /webdev/index.html
      ansible.builtin.copy:
        content: "Development"
        dest: /webdev/index.html
        mode: "0640"
        owner: www-data
        group: webdev
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/web.yml
ansible-playbook playbooks/web.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,file,symlink,permissions,group"}'
