#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/hwreport.yml\` that deploys \`/root/hwreport.txt\` on all hosts using template \`/home/ansible_user/workspace/hwreport.j2\`. The template reports: inventory hostname, total memory (MB), BIOS version, and disk sizes for sda and sdb (use NULL if sdb is not defined). Use block/rescue: try to deploy hwreport.j2; on failure deploy hwreport2.j2 (with NULL for sdb)."
    hint="Use \`ansible_facts['devices']['sdb'] is defined\` in the Jinja2 template to handle missing sdb. The block/rescue pattern handles systems where certain facts may fail."
    inst1="Create the template /home/ansible_user/workspace/hwreport.j2:"
    inst2="Create the fallback template /home/ansible_user/workspace/hwreport2.j2 (with NULL for sdb):"
    inst3="Create the playbook /home/ansible_user/workspace/hwreport.yml with block/rescue:"
    inst4="Run the playbook:"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/hwreport.yml\` qui déploie \`/root/hwreport.txt\` sur tous les hôtes en utilisant le template \`/home/ansible_user/workspace/hwreport.j2\`. Le template rapporte : le nom d'hôte d'inventaire, la mémoire totale (Mo), la version BIOS, et les tailles des disques sda et sdb (utilisez NULL si sdb n'est pas défini). Utilisez block/rescue : essayez de déployer hwreport.j2 ; en cas d'échec, déployez hwreport2.j2 (avec NULL pour sdb)."
    hint="Utilisez \`ansible_facts['devices']['sdb'] is defined\` dans le template Jinja2 pour gérer sdb manquant. Le pattern block/rescue gère les systèmes où certains faits peuvent échouer."
    inst1="Créez le template /home/ansible_user/workspace/hwreport.j2 :"
    inst2="Créez le template de secours /home/ansible_user/workspace/hwreport2.j2 (avec NULL pour sdb) :"
    inst3="Créez le playbook /home/ansible_user/workspace/hwreport.yml avec block/rescue :"
    inst4="Exécutez le playbook :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_template='```jinja2
-- Inventory host name: {{ ansible_facts["hostname"] }}
-- Total memory in MB: {{ ansible_facts["memtotal_mb"] }}
-- BIOS version: {{ ansible_facts["bios_version"] }}
-- Size of disk device sda: {{ ansible_facts["devices"]["sda"]["size"] }}
{% if ansible_facts["devices"]["sdb"] is defined %}
-- Size of disk device sdb: {{ ansible_facts["devices"]["sdb"]["size"] }}
{% else %}
-- Size of disk device sdb: NULL
{% endif %}
```'

cmd_template2='```jinja2
-- Inventory host name: {{ ansible_facts["hostname"] }}
-- Total memory in MB: {{ ansible_facts["memtotal_mb"] }}
-- BIOS version: {{ ansible_facts["bios_version"] }}
-- Size of disk device sda: {{ ansible_facts["devices"]["sda"]["size"] }}
-- Size of disk device sdb: NULL
```'

cmd_playbook='```yaml
- name: Generate hardware report
  hosts: all
  become: true
  tasks:
    - name: Deploy hardware report
      block:
        - name: Try deploying hwreport.j2
          ansible.builtin.template:
            src: hwreport.j2
            dest: /root/hwreport.txt
            owner: root
            group: root
            mode: "0644"
      rescue:
        - name: Deploy fallback hwreport2.j2
          ansible.builtin.template:
            src: hwreport2.j2
            dest: /root/hwreport.txt
            owner: root
            group: root
            mode: "0644"
```'

cmd_run='```bash
ansible-playbook playbooks/hwreport.yml
ansible all -m command -a "cat /root/hwreport.txt"
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_template" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_template2" \
  --arg inst3 "$inst3" --arg cmd3 "$cmd_playbook" \
  --arg inst4 "$inst4" --arg cmd4 "$cmd_run" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}, {"instruction": $inst3, "command": $cmd3}, {"instruction": $inst4, "command": $cmd4}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,template,jinja2,facts,block,rescue,hardware"}'
