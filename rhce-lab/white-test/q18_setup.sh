#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/selinux.yml\` that uses \`ansible.posix.selinux\` module on all hosts to set SELinux state to \`permissive\` with policy \`targeted\`. Note: Ubuntu uses AppArmor instead of SELinux; the playbook should be structured correctly even if it cannot fully apply on this lab environment."
    hint="Use the \`ansible.posix.selinux\` module with \`state: permissive\` and \`policy: targeted\`. Set \`become: true\`. This exercise tests your knowledge of the module structure even on non-RHEL systems."
    inst1="Create the playbook /home/ansible_user/workspace/selinux.yml:"
    inst2="Check syntax:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/selinux.yml\` qui utilise le module \`ansible.posix.selinux\` sur tous les hôtes pour définir l'état SELinux à \`permissive\` avec la politique \`targeted\`. Note : Ubuntu utilise AppArmor au lieu de SELinux ; le playbook doit être correctement structuré même s'il ne peut pas s'appliquer pleinement dans cet environnement de lab."
    hint="Utilisez le module \`ansible.posix.selinux\` avec \`state: permissive\` et \`policy: targeted\`. Définissez \`become: true\`. Cet exercice teste votre connaissance de la structure du module même sur des systèmes non-RHEL."
    inst1="Créez le playbook /home/ansible_user/workspace/selinux.yml :"
    inst2="Vérifiez la syntaxe :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Configure SELinux state
  hosts: all
  become: true
  vars:
    selinux_state: permissive
    selinux_policy: targeted
  tasks:
    - name: Set SELinux to permissive mode
      ansible.posix.selinux:
        state: "{{ selinux_state }}"
        policy: "{{ selinux_policy }}"
      ignore_errors: true
```'

cmd_check='```bash
ansible-playbook --syntax-check playbooks/selinux.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,selinux,ansible.posix,security,permissive"}'
