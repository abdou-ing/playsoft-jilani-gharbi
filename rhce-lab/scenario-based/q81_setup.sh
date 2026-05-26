#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

solution="ansible.builtin.user"

cmd1="ansible-doc -l | grep -i 'user'"
cmd2="ansible-doc ansible.builtin.user | grep -A5 'password_expire'"

case "$lang" in
  en)
    question="You need to set a password expiry policy for john on the managed hosts. Search the Ansible module list to find the built-in module that manages local user accounts — including shell, home directory, groups, and password aging. Type the full module name below."
    hint="Run: ansible-doc -l | grep -i 'user' to list all user-related modules. Then inspect the winner with: ansible-doc ansible.builtin.user | grep -A5 'password_expire'. The answer is the fully qualified module name."
    inst1="Search for user-related modules in the Ansible documentation:"
    inst2="Inspect the module to confirm it supports password aging parameters:"
    ;;
  fr)
    question="Vous devez définir une politique d'expiration de mot de passe pour john sur les hôtes gérés. Recherchez dans la liste des modules Ansible le module intégré qui gère les comptes utilisateurs locaux — y compris le shell, le répertoire home, les groupes et le vieillissement des mots de passe. Tapez le nom complet du module ci-dessous."
    hint="Exécutez : ansible-doc -l | grep -i 'user' pour lister tous les modules liés aux utilisateurs. Ensuite inspectez le bon avec : ansible-doc ansible.builtin.user | grep -A5 'password_expire'. La réponse est le nom complet du module."
    inst1="Recherchez les modules liés aux utilisateurs dans la documentation Ansible :"
    inst2="Inspectez le module pour confirmer qu'il supporte les paramètres de vieillissement de mot de passe :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2; exit 1 ;;
esac

instructions=$(jq -n --arg inst1 "$inst1" --arg cmd1 "$cmd1" --arg inst2 "$inst2" --arg cmd2 "$cmd2" \
  '[{"instruction": $inst1, "command": $cmd1}, {"instruction": $inst2, "command": $cmd2}]')

jq -n --indent 4 \
  --arg question "$question" \
  --arg hint "$hint" \
  --arg solution "$solution" \
  --argjson instructions "$instructions" \
  '{
    "question": $question,
    "type": "text",
    "solution": $solution,
    "hint": $hint,
    "instructions": $instructions,
    "plateforme_required": "container",
    "os_required": "ubuntu",
    "tags": "ansible,user,module,rhce"
  }'
