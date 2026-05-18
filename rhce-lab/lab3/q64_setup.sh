#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/os_report.yml\` that generates \`/root/os_report.txt\` on all managed hosts. The file must contain the following lines filled with Ansible Facts:\n\nOS=\`ansible_distribution\`\nVERSION=\`ansible_distribution_version\`\nKERNEL=\`ansible_kernel\`\n\nUse the \`lineinfile\` module for each line."
    hint="Use \`ansible_distribution\` for the OS name (e.g. Ubuntu), \`ansible_distribution_version\` for the version (e.g. 22.04), and \`ansible_kernel\` for the kernel version. Add \`create: yes\` to create the file if it does not exist."
    inst1="Create the playbook at ~/playbooks/os_report.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/os_report.yml\` qui génère \`/root/os_report.txt\` sur tous les hôtes gérés. Le fichier doit contenir les lignes suivantes remplies avec les Ansible Facts :\n\nOS=\`ansible_distribution\`\nVERSION=\`ansible_distribution_version\`\nKERNEL=\`ansible_kernel\`\n\nUtilisez le module \`lineinfile\` pour chaque ligne."
    hint="Utilisez \`ansible_distribution\` pour le nom du système (ex. Ubuntu), \`ansible_distribution_version\` pour la version (ex. 22.04), et \`ansible_kernel\` pour la version du noyau. Ajoutez \`create: yes\` pour créer le fichier s'il n'existe pas."
    inst1="Créez le playbook dans ~/playbooks/os_report.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Generate OS report file
  hosts: all
  become: true
  tasks:
    - name: Set OS line
      lineinfile:
        path: /root/os_report.txt
        regexp: "^OS="
        line: "OS={{ ansible_distribution }}"
        create: yes

    - name: Set VERSION line
      lineinfile:
        path: /root/os_report.txt
        regexp: "^VERSION="
        line: "VERSION={{ ansible_distribution_version }}"
        create: yes

    - name: Set KERNEL line
      lineinfile:
        path: /root/os_report.txt
        regexp: "^KERNEL="
        line: "KERNEL={{ ansible_kernel }}"
        create: yes
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/os_report.yml
ansible-playbook playbooks/os_report.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,facts,os,lineinfile"}'
