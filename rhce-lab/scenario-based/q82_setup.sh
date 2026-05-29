#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/shared_dir.yml"

# Clean state: remove /srv/devproject from webservers
ansible webservers -i "$inventory" -m file \
  -a "path=/srv/devproject state=absent" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: create shared project directory on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: ensure developers group exists
      ansible.builtin.group:
        name: developers
        state: present

    - name: create /srv/devproject with setgid
      ansible.builtin.file:
        path: /srv/devproject
        state: directory
        group: developers
        mode: "02775"
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'stat -c \"%G %a\" /srv/devproject' --become
\`\`\`"

case "$lang" in
  en)
    question="The team needs a shared directory for collaboration. Write a playbook at \`$pb_path\` that creates \`/srv/devproject\` on all \`webservers\` owned by the \`developers\` group with mode \`02775\` (**setgid + group-writable**). The setgid bit ensures **new files inherit the group**. Run it."
    hint="Use ansible.builtin.file with: path: /srv/devproject, state: directory, group: developers, mode: '02775'. The leading '2' sets the setgid bit. First ensure the developers group exists with ansible.builtin.group. Verify: ansible webservers -m command -a 'stat -c \"%G %a\" /srv/devproject' --become"
    inst1="Write the playbook at \`$pb_path\` — create the group first, then the directory with mode \`02775\` (setgid):"
    inst2="Run the playbook and verify the directory permissions on all webservers:"
    ;;
  fr)
    question="L'équipe a besoin d'un répertoire partagé pour la collaboration. Écrivez un playbook à \`$pb_path\` qui crée \`/srv/devproject\` sur tous les \`webservers\` appartenant au groupe \`developers\` avec le mode \`02775\` (**setgid + écriture groupe**). Le bit setgid garantit que les **nouveaux fichiers héritent du groupe**. Exécutez-le."
    hint="Utilisez ansible.builtin.file avec : path: /srv/devproject, state: directory, group: developers, mode: '02775'. Le '2' initial définit le bit setgid. Assurez d'abord que le groupe developers existe avec ansible.builtin.group. Vérifiez : ansible webservers -m command -a 'stat -c \"%G %a\" /srv/devproject' --become"
    inst1="Écrivez le playbook à \`$pb_path\` — créez d'abord le groupe, puis le répertoire avec le mode \`02775\` (setgid) :"
    inst2="Exécutez le playbook et vérifiez les permissions du répertoire sur tous les webservers :"
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
    "tags": "ansible,file,setgid,permissions,group,rhce"
  }'
