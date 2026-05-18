#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi

_PODMAN="sudo -u student env XDG_RUNTIME_DIR=/run/user/1000 podman"
if $_PODMAN ps --format '{{.Names}}' 2>/dev/null | grep -q "^control-node$"; then
  $_PODMAN exec -i control-node bash -s -- "$@" < "$0"
  exit $?
fi

lang="en"
if [[ "$1" == "fr" ]]; then lang="$1"; shift; fi

declare -A messages_en=(
  ["no_playbook"]="Playbook ~/playbooks/os_report.yml not found. Create it first."
  ["syntax_error"]="Playbook has syntax errors. Run: ansible-playbook --syntax-check playbooks/os_report.yml"
  ["no_os_var"]="Playbook does not use ansible_distribution. Use {{ ansible_distribution }} for the OS= line."
  ["no_version_var"]="Playbook does not use ansible_distribution_version. Use {{ ansible_distribution_version }} for the VERSION= line."
  ["no_kernel_var"]="Playbook does not use ansible_kernel. Use {{ ansible_kernel }} for the KERNEL= line."
  ["no_file"]="File /root/os_report.txt not found on all hosts. Run: ansible-playbook playbooks/os_report.yml"
  ["os_wrong"]="OS= line in /root/os_report.txt does not match ansible_distribution on one or more hosts."
  ["version_wrong"]="VERSION= line in /root/os_report.txt does not match ansible_distribution_version on one or more hosts."
  ["kernel_wrong"]="KERNEL= line in /root/os_report.txt does not match ansible_kernel on one or more hosts."
)
declare -A messages_fr=(
  ["no_playbook"]="Le playbook ~/playbooks/os_report.yml est introuvable. Créez-le d'abord."
  ["syntax_error"]="Le playbook contient des erreurs de syntaxe. Exécutez : ansible-playbook --syntax-check playbooks/os_report.yml"
  ["no_os_var"]="Le playbook n'utilise pas ansible_distribution. Utilisez {{ ansible_distribution }} pour la ligne OS=."
  ["no_version_var"]="Le playbook n'utilise pas ansible_distribution_version. Utilisez {{ ansible_distribution_version }} pour la ligne VERSION=."
  ["no_kernel_var"]="Le playbook n'utilise pas ansible_kernel. Utilisez {{ ansible_kernel }} pour la ligne KERNEL=."
  ["no_file"]="Le fichier /root/os_report.txt est introuvable sur tous les hôtes. Exécutez : ansible-playbook playbooks/os_report.yml"
  ["os_wrong"]="La ligne OS= dans /root/os_report.txt ne correspond pas à ansible_distribution sur un ou plusieurs hôtes."
  ["version_wrong"]="La ligne VERSION= dans /root/os_report.txt ne correspond pas à ansible_distribution_version sur un ou plusieurs hôtes."
  ["kernel_wrong"]="La ligne KERNEL= dans /root/os_report.txt ne correspond pas à ansible_kernel sur un ou plusieurs hôtes."
)

get_message() { declare -n _m="messages_$lang"; echo "{\"result\": \"${_m[$1]}\"}"; }

cd /home/ansible_user

# CHECK 1 — playbook file must exist
[ -f "playbooks/os_report.yml" ] || { echo "$(get_message no_playbook)"; exit 0; }

# CHECK 2 — playbook must have no syntax errors
ansible-playbook --syntax-check playbooks/os_report.yml &>/dev/null || { echo "$(get_message syntax_error)"; exit 0; }

# CHECK 3 — playbook must reference ansible_distribution
grep -q "ansible_distribution\b" playbooks/os_report.yml || { echo "$(get_message no_os_var)"; exit 0; }

# CHECK 4 — playbook must reference ansible_distribution_version
grep -q "ansible_distribution_version" playbooks/os_report.yml || { echo "$(get_message no_version_var)"; exit 0; }

# CHECK 5 — playbook must reference ansible_kernel
grep -q "ansible_kernel" playbooks/os_report.yml || { echo "$(get_message no_kernel_var)"; exit 0; }

# CHECK 6 — /root/os_report.txt must exist on all hosts
ansible all -m command -a "test -f /root/os_report.txt" &>/dev/null 2>&1 || { echo "$(get_message no_file)"; exit 0; }

# CHECK 7 — OS= must match ansible_distribution (from /etc/os-release NAME field)
ansible all -m shell -a "
  actual_os=\$(. /etc/os-release 2>/dev/null && echo \"\$NAME\")
  grep -q \"^OS=\${actual_os}\$\" /root/os_report.txt
" &>/dev/null 2>&1 || { echo "$(get_message os_wrong)"; exit 0; }

# CHECK 8 — VERSION= must match ansible_distribution_version (from /etc/os-release VERSION_ID)
ansible all -m shell -a "
  actual_ver=\$(. /etc/os-release 2>/dev/null && echo \"\$VERSION_ID\")
  grep -q \"^VERSION=\${actual_ver}\$\" /root/os_report.txt
" &>/dev/null 2>&1 || { echo "$(get_message version_wrong)"; exit 0; }

# CHECK 9 — KERNEL= must match ansible_kernel (uname -r)
ansible all -m shell -a "
  actual_kernel=\$(uname -r)
  grep -q \"^KERNEL=\${actual_kernel}\$\" /root/os_report.txt
" &>/dev/null 2>&1 || { echo "$(get_message kernel_wrong)"; exit 0; }

echo '{"result": "0"}'
