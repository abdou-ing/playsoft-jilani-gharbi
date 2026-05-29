#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/ssh_banner.yml"
banner_file="/home/ansible_user/workspace/motd_banner.txt"

# Clean state: remove banner from webservers
ansible webservers -i "$inventory" -m file \
  -a "path=/etc/ssh/banner state=absent" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m lineinfile \
  -a "path=/etc/ssh/sshd_config regexp='^Banner' state=absent" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m service \
  -a "name=ssh state=restarted" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

# Ensure the banner source file exists on the control node
if [ ! -f "$banner_file" ]; then
  { printf 'WARNING: Authorized access only. All activity is monitored and logged.\n' > "$banner_file"; } 2>/dev/null || true
fi

cmd1='```yaml
---
- name: deploy SSH login banner on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: copy banner file
      ansible.builtin.copy:
        src: /home/ansible_user/workspace/motd_banner.txt
        dest: /etc/ssh/banner
        owner: root
        group: root
        mode: "0644"

    - name: set Banner directive in sshd_config
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^Banner"
        line: "Banner /etc/ssh/banner"

    - name: restart sshd
      ansible.builtin.service:
        name: ssh
        state: restarted
```'
cmd2="\`\`\`shell
ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'cat /etc/ssh/banner' --become
\`\`\`"

case "$lang" in
  en)
    question="Legal requires a **warning banner** displayed to users on **SSH login** for all \`webservers\`. A banner file already exists at \`$banner_file\` on the control node. Write a playbook at \`$pb_path\` that copies this file to \`/etc/ssh/banner\` on each webserver, sets the \`Banner\` directive in \`/etc/ssh/sshd_config\`, and **restarts SSH**."
    hint="Use ansible.builtin.copy to deploy the banner file, then ansible.builtin.lineinfile to set 'Banner /etc/ssh/banner' in sshd_config. Finally restart the ssh service. Verify with: ansible webservers -m command -a 'cat /etc/ssh/banner' --become"
    inst1="Write the playbook at \`$pb_path\` — copy the banner, configure the \`Banner\` directive, then restart SSH:"
    inst2="Run the playbook and verify the banner is deployed on all webservers:"
    ;;
  fr)
    question="La direction juridique exige qu'une **bannière d'avertissement** soit affichée lors de la **connexion SSH** sur tous les \`webservers\`. Un fichier de bannière existe déjà à \`$banner_file\` sur le nœud de contrôle. Écrivez un playbook à \`$pb_path\` qui copie ce fichier vers \`/etc/ssh/banner\` sur chaque webserver, définit la directive \`Banner\` dans \`/etc/ssh/sshd_config\`, et **redémarre SSH**."
    hint="Utilisez ansible.builtin.copy pour déployer le fichier de bannière, puis ansible.builtin.lineinfile pour définir 'Banner /etc/ssh/banner' dans sshd_config. Ensuite redémarrez le service ssh. Vérifiez avec : ansible webservers -m command -a 'cat /etc/ssh/banner' --become"
    inst1="Écrivez le playbook à \`$pb_path\` — copiez la bannière, configurez la directive \`Banner\`, puis redémarrez SSH :"
    inst2="Exécutez le playbook et vérifiez que la bannière est déployée sur tous les webservers :"
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
    "tags": "ansible,copy,lineinfile,ssh,banner,service,rhce"
  }'
