#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Create \`/home/ansible_user/workspace/storage.yml\` that uses block/rescue/always to manage LVM on all hosts: in block, create LV 'data' of 1500m in VG 'research' (register: lv_info); in rescue, debug messages based on the failure reason, and create LV 'data' of 800m if space was insufficient; in always, create an ext4 filesystem on /dev/research/data."
    hint="Use the \`lvol\` module for LVM. The rescue section must check if 'does not exist' is in lv_info.msg (VG missing) or 'insufficient' is in lv_info.err (not enough space). The always section runs the \`filesystem\` module regardless."
    inst1="Create the playbook /home/ansible_user/workspace/storage.yml:"
    inst2="Check syntax (do not run unless real disks are available):"
    ;;
  fr)
    question="Créez \`/home/ansible_user/workspace/storage.yml\` qui utilise block/rescue/always pour gérer LVM sur tous les hôtes : dans block, créez le LV 'data' de 1500m dans le VG 'research' (register: lv_info) ; dans rescue, déboguez les messages selon la raison de l'échec, et créez le LV 'data' de 800m si l'espace était insuffisant ; dans always, créez un système de fichiers ext4 sur /dev/research/data."
    hint="Utilisez le module \`lvol\` pour LVM. La section rescue doit vérifier si 'does not exist' est dans lv_info.msg (VG manquant) ou 'insufficient' est dans lv_info.err (espace insuffisant). La section always exécute le module \`filesystem\` quoi qu'il arrive."
    inst1="Créez le playbook /home/ansible_user/workspace/storage.yml :"
    inst2="Vérifiez la syntaxe (ne pas exécuter sauf si de vrais disques sont disponibles) :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

cmd_playbook='```yaml
- name: Manage LVM storage with block/rescue/always
  hosts: all
  become: true
  tasks:
    - name: Manage LVM logical volume
      block:
        - name: Create LV data 1500m in VG research
          community.general.lvol:
            vg: research
            lv: data
            size: 1500m
          register: lv_info

      rescue:
        - name: Debug if VG does not exist
          ansible.builtin.debug:
            msg: "VG Not found"
          when: '"'"'does not exist'"'"' in lv_info.msg | default("")

        - name: Debug if insufficient space
          ansible.builtin.debug:
            msg: "LV Can not be created with following size"
          when: '"'"'insufficient'"'"' in lv_info.err | default("")

        - name: Create smaller LV data 800m when space is insufficient
          community.general.lvol:
            vg: research
            lv: data
            size: 800m
          when: '"'"'insufficient'"'"' in lv_info.err | default("")

      always:
        - name: Create ext4 filesystem on /dev/research/data
          community.general.filesystem:
            fstype: ext4
            dev: /dev/research/data
```'

cmd_check='```bash
ansible-playbook --syntax-check playbooks/storage.yml
```'

instructions=$(jq -n \
  --arg inst1 "$inst1" --arg cmd1 "$cmd_playbook" \
  --arg inst2 "$inst2" --arg cmd2 "$cmd_check" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" --arg hint "$hint" --argjson instructions "$instructions" \
  '{"question": $question, "plateforme_required": "container", "os_required": "ubuntu", "type": "button", "hint": $hint, "instructions": $instructions, "text": "Check", "tags": "ansible,rhce,playbook,lvm,storage,block,rescue,always,filesystem"}'
