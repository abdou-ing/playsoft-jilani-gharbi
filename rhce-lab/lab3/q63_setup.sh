#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/network_info.yml\` that generates \`/root/network_info.txt\` on all managed hosts. The file must contain the following lines filled with Ansible Facts:\n\nIP=\`ansible_default_ipv4.address\`\nFQDN=\`ansible_fqdn\`\n\nUse the \`lineinfile\` module for each line."
    hint="Use \`ansible_default_ipv4.address\` for the IP address and \`ansible_fqdn\` for the fully qualified domain name. Add \`create: yes\` to create the file if it does not exist."
    inst1="Create the playbook at ~/playbooks/network_info.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/network_info.yml\` qui génère \`/root/network_info.txt\` sur tous les hôtes gérés. Le fichier doit contenir les lignes suivantes remplies avec les Ansible Facts :\n\nIP=\`ansible_default_ipv4.address\`\nFQDN=\`ansible_fqdn\`\n\nUtilisez le module \`lineinfile\` pour chaque ligne."
    hint="Utilisez \`ansible_default_ipv4.address\` pour l'adresse IP et \`ansible_fqdn\` pour le nom de domaine complet. Ajoutez \`create: yes\` pour créer le fichier s'il n'existe pas."
    inst1="Créez le playbook dans ~/playbooks/network_info.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Generate network info file
  hosts: all
  become: true
  tasks:
    - name: Set IP line
      lineinfile:
        path: /root/network_info.txt
        regexp: "^IP="
        line: "IP={{ ansible_default_ipv4.address }}"
        create: yes

    - name: Set FQDN line
      lineinfile:
        path: /root/network_info.txt
        regexp: "^FQDN="
        line: "FQDN={{ ansible_fqdn }}"
        create: yes
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/network_info.yml
ansible-playbook playbooks/network_info.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,facts,network,lineinfile"}'
