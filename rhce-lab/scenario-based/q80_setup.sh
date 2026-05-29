#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/sudo_access.yml"

# Skip-q78 guard: ensure john exists
ansible webservers -i "$inventory" -m user \
  -a "name=john create_home=yes shell=/bin/bash state=present" \
  --become -o >/dev/null 2>&1 || true

# Clean state: remove sudoers file for john
ansible webservers -i "$inventory" -m file \
  -a "path=/etc/sudoers.d/john state=absent" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: grant john sudo access on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: deploy sudoers drop-in file for john
      ansible.builtin.copy:
        content: "john ALL=(ALL) NOPASSWD:ALL\n"
        dest: /etc/sudoers.d/john
        owner: root
        group: root
        mode: "0440"
        validate: /usr/sbin/visudo -cf %s
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'sudo -l -U john' --become
\`\`\`"

case "$lang" in
  en)
    question="John cannot run administrative tasks yet. Write a playbook at \`$pb_path\` that grants him **full sudo access** on all \`webservers\` by deploying a sudoers drop-in file at \`/etc/sudoers.d/john\`. The file must be **validated with visudo** before being applied — **never copy an unvalidated sudoers file**. Run the playbook."
    hint="Use ansible.builtin.copy with: content: 'john ALL=(ALL) NOPASSWD:ALL\n', dest: /etc/sudoers.d/john, mode: '0440', validate: /usr/sbin/visudo -cf %s. The validate parameter runs visudo on the temp file before writing — this prevents syntax errors from breaking sudo."
    inst1="Write the playbook at \`$pb_path\` using \`ansible.builtin.copy\` with the \`validate\` parameter to safely deploy the sudoers drop-in file:"
    inst2="Run the playbook and verify john has sudo access on all webservers:"
    ;;
  fr)
    question="John ne peut pas encore exécuter des tâches administratives. Écrivez un playbook à \`$pb_path\` qui lui accorde **l'accès sudo complet** sur tous les \`webservers\` en déployant un fichier sudoers drop-in à \`/etc/sudoers.d/john\`. Le fichier doit être **validé avec visudo** avant d'être appliqué. Exécutez le playbook."
    hint="Utilisez ansible.builtin.copy avec : content: 'john ALL=(ALL) NOPASSWD:ALL\n', dest: /etc/sudoers.d/john, mode: '0440', validate: /usr/sbin/visudo -cf %s. Le paramètre validate exécute visudo sur le fichier temporaire avant l'écriture — cela évite les erreurs de syntaxe qui casseraient sudo."
    inst1="Écrivez le playbook à \`$pb_path\` avec \`ansible.builtin.copy\` et le paramètre \`validate\` pour déployer le fichier sudoers drop-in en toute sécurité :"
    inst2="Exécutez le playbook et vérifiez que john dispose de l'accès sudo sur tous les webservers :"
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
    "tags": "ansible,copy,sudo,sudoers,validate,rhce"
  }'
