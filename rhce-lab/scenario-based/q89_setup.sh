#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

inventory="/home/ansible_user/workspace/inventory"
pb_path="/home/ansible_user/workspace/ntp_config.yml"

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

# Clean state: remove NTP server config from webservers
ansible webservers -i "$inventory" -m lineinfile \
  -a "path=/etc/systemd/timesyncd.conf regexp='^NTP=' state=absent" \
  --become -o >/dev/null 2>&1 || true
ansible webservers -i "$inventory" -m service \
  -a "name=systemd-timesyncd state=restarted" \
  --become -o >/dev/null 2>&1 || true
rm -f "$pb_path"

cmd1='```yaml
---
- name: configure NTP on webservers
  hosts: webservers
  become: yes
  tasks:
    - name: set NTP server in timesyncd.conf
      ansible.builtin.lineinfile:
        path: /etc/systemd/timesyncd.conf
        regexp: "^NTP="
        line: "NTP=pool.ntp.org"

    - name: restart systemd-timesyncd
      ansible.builtin.service:
        name: systemd-timesyncd
        state: restarted
        enabled: yes
```'
cmd2="ansible-playbook -i $inventory $pb_path
ansible webservers -i $inventory -m command -a 'grep NTP /etc/systemd/timesyncd.conf' --become"

case "$lang" in
  en)
    question="All \`webservers\` must synchronize time using \`pool.ntp.org\`. Write a playbook at \`$pb_path\` that sets \`NTP=pool.ntp.org\` in \`/etc/systemd/timesyncd.conf\` using \`lineinfile\`, then restarts and enables the \`systemd-timesyncd\` service."
    hint="Use ansible.builtin.lineinfile with regexp: '^NTP=' and line: 'NTP=pool.ntp.org' to set the NTP server. Then use ansible.builtin.service with name: systemd-timesyncd, state: restarted, enabled: yes. Verify: ansible webservers -m command -a 'grep NTP /etc/systemd/timesyncd.conf' --become"
    inst1="Write the playbook — configure the <span class=\"bold-green-text\">NTP</span> server with lineinfile, then restart timesyncd:"
    inst2="Run the playbook and verify the NTP configuration on all webservers:"
    ;;
  fr)
    question="Tous les \`webservers\` doivent synchroniser l'heure avec \`pool.ntp.org\`. Écrivez un playbook à \`$pb_path\` qui définit \`NTP=pool.ntp.org\` dans \`/etc/systemd/timesyncd.conf\` avec \`lineinfile\`, puis redémarre et active le service \`systemd-timesyncd\`."
    hint="Utilisez ansible.builtin.lineinfile avec regexp: '^NTP=' et line: 'NTP=pool.ntp.org' pour définir le serveur NTP. Ensuite utilisez ansible.builtin.service avec name: systemd-timesyncd, state: restarted, enabled: yes. Vérifiez : ansible webservers -m command -a 'grep NTP /etc/systemd/timesyncd.conf' --become"
    inst1="Écrivez le playbook — configurez le serveur <span class=\"bold-green-text\">NTP</span> avec lineinfile, puis redémarrez timesyncd :"
    inst2="Exécutez le playbook et vérifiez la configuration NTP sur tous les webservers :"
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
    "tags": "ansible,lineinfile,ntp,service,timesyncd,rhce"
  }'
