#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create a playbook at \`~/playbooks/report.yml\` that generates \`/root/report.txt\` on all managed hosts. The file must contain the following lines filled with the actual values from Ansible Facts:\n\nHOST=\`ansible_hostname\`\nMEMORY=\`ansible_memtotal_mb\`\nBIOS=\`ansible_bios_version\`\nSDA_DISK_SIZE=\`ansible_devices.sda.size\`\nSDB_DISK_SIZE=\`ansible_devices.sdb.size\`\n\nUse the \`lineinfile\` module to set each value. The playbook must target all managed hosts."
    hint="Use \`gather_facts: true\` (default) so Ansible Facts are available. Use \`lineinfile\` with \`regexp\` to match the key and \`line\` to set the value. Use \`create: yes\` to create the file if it does not exist."
    inst1="Create the playbook at ~/playbooks/report.yml:"
    inst2="Check syntax then run the playbook:"
    ;;
  fr)
    question="Créez un playbook dans \`~/playbooks/report.yml\` qui génère \`/root/report.txt\` sur tous les hôtes gérés. Le fichier doit contenir les lignes suivantes remplies avec les valeurs réelles des Ansible Facts :\n\nHOST=\`ansible_hostname\`\nMEMORY=\`ansible_memtotal_mb\`\nBIOS=\`ansible_bios_version\`\nSDA_DISK_SIZE=\`ansible_devices.sda.size\`\nSDB_DISK_SIZE=\`ansible_devices.sdb.size\`\n\nUtilisez le module \`lineinfile\` pour définir chaque valeur. Le playbook doit cibler tous les hôtes gérés."
    hint="Utilisez \`gather_facts: true\` (par défaut) pour que les Ansible Facts soient disponibles. Utilisez \`lineinfile\` avec \`regexp\` pour identifier la clé et \`line\` pour définir la valeur. Ajoutez \`create: yes\` pour créer le fichier s'il n'existe pas."
    inst1="Créez le playbook dans ~/playbooks/report.yml :"
    inst2="Vérifiez la syntaxe puis exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Generate system report on all hosts
  hosts: all
  become: true
  tasks:
    - name: Set HOST line
      lineinfile:
        path: /root/report.txt
        regexp: "^HOST="
        line: "HOST={{ ansible_hostname }}"
        create: yes

    - name: Set MEMORY line
      lineinfile:
        path: /root/report.txt
        regexp: "^MEMORY="
        line: "MEMORY={{ ansible_memtotal_mb }}"
        create: yes

    - name: Set BIOS line
      lineinfile:
        path: /root/report.txt
        regexp: "^BIOS="
        line: "BIOS={{ ansible_bios_version }}"
        create: yes

    - name: Set SDA_DISK_SIZE line
      lineinfile:
        path: /root/report.txt
        regexp: "^SDA_DISK_SIZE="
        line: "SDA_DISK_SIZE={{ ansible_devices.sda.size }}"
        create: yes

    - name: Set SDB_DISK_SIZE line
      lineinfile:
        path: /root/report.txt
        regexp: "^SDB_DISK_SIZE="
        line: "SDB_DISK_SIZE={{ ansible_devices.sdb.size }}"
        create: yes
```'

cmd_run='```bash
ansible-playbook --syntax-check playbooks/report.yml
ansible-playbook playbooks/report.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,facts,variables,lineinfile"}'
