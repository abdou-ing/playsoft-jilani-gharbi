#!/bin/bash
if [[ "$1" == "debug" ]]; then set -eoux; shift; fi
lang="${1:-en}"

case "$lang" in
  en)
    question="Test Ansible connectivity to all managed nodes using the \`ping\` module. Both \`web1\` and \`web2\` must respond with \`SUCCESS\`."
    hint="Make sure ansible.cfg and the inventory file are in place before running. The ping module does not use ICMP — it tests the Python connection over SSH."
    inst1="Run the Ansible ping module against all hosts:"
    ;;
  fr)
    question="Testez la connectivité Ansible vers tous les nœuds gérés en utilisant le module \`ping\`. \`web1\` et \`web2\` doivent tous deux répondre avec \`SUCCESS\`."
    hint="Assurez-vous qu'ansible.cfg et le fichier d'inventaire sont en place avant d'exécuter. Le module ping n'utilise pas ICMP — il teste la connexion Python via SSH."
    inst1="Exécutez le module Ansible ping sur tous les hôtes :"
    ;;
  *)
    echo "Error: Unsupported language '$lang'. Use en or fr." >&2
    exit 1
    ;;
esac

instructions=$(jq -n \
  --arg inst1 "$inst1" \
  '[{"instruction": $inst1, "command": "ansible all -m ping"}]')

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
    "tags": "ansible,rhce,ping,connectivity"
  }'
