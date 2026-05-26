#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/ssh_banner.yml"
banner_file="/home/ansible_user/workspace/motd_banner.txt"

# Skip-q60 guard
if [ ! -f "$inventory" ]; then
  mkdir -p /home/ansible_user/workspace
  printf '[webservers]\nweb1\nweb2\n\n[dbservers]\nbd1\n\n[all:vars]\nansible_user=ansible_user\n' > "$inventory"
fi
for entry in "10.30.0.11 web1" "10.30.0.12 web2" "10.30.0.13 bd1"; do
  grep -qF "${entry%% *}" /etc/hosts 2>/dev/null || printf '%s\n' "$entry" | sudo tee -a /etc/hosts >/dev/null 2>&1 || true
done
if [ ! -f "/home/ansible_user/.ssh/id_rsa" ]; then
  ssh-keygen -t rsa -b 2048 -f /home/ansible_user/.ssh/id_rsa -N "" >/dev/null 2>&1
  for _h in web1 web2 bd1; do
    SSHPASS='Labby123' sshpass -e ssh-copy-id -o StrictHostKeyChecking=no \
      -i /home/ansible_user/.ssh/id_rsa.pub ansible_user@"$_h" >/dev/null 2>&1 || true
  done
fi

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
  printf 'WARNING: Authorized access only. All activity is monitored and logged.\n' > "$banner_file"
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
cmd2="ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'cat /etc/ssh/banner' --become"

case "$lang" in
  en)
    question="Legal requires a warning banner displayed to users on SSH login for all \`webservers\`. A banner file already exists at \`$banner_file\` on the control node. Write a playbook at \`$pb_path\` that copies this file to \`/etc/ssh/banner\` on each webserver, sets the \`Banner\` directive in \`/etc/ssh/sshd_config\`, and restarts SSH."
    hint="Use ansible.builtin.copy to deploy the banner file, then ansible.builtin.lineinfile to set 'Banner /etc/ssh/banner' in sshd_config. Finally restart the ssh service. Verify with: ansible webservers -m command -a 'cat /etc/ssh/banner' --become"
    inst1="Write the playbook — copy the banner, configure the <span class=\"bold-green-text\">Banner</span> directive, then restart SSH:"
    inst2="Run the playbook and verify the banner is deployed on all webservers:"
    ;;
  fr)
    question="La direction juridique exige qu'une bannière d'avertissement soit affichée lors de la connexion SSH sur tous les \`webservers\`. Un fichier de bannière existe déjà à \`$banner_file\` sur le nœud de contrôle. Écrivez un playbook à \`$pb_path\` qui copie ce fichier vers \`/etc/ssh/banner\` sur chaque webserver, définit la directive \`Banner\` dans \`/etc/ssh/sshd_config\`, et redémarre SSH."
    hint="Utilisez ansible.builtin.copy pour déployer le fichier de bannière, puis ansible.builtin.lineinfile pour définir 'Banner /etc/ssh/banner' dans sshd_config. Ensuite redémarrez le service ssh. Vérifiez avec : ansible webservers -m command -a 'cat /etc/ssh/banner' --become"
    inst1="Écrivez le playbook — copiez la bannière, configurez la directive <span class=\"bold-green-text\">Banner</span>, puis redémarrez SSH :"
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
