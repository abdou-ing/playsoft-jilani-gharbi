#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="Which Ansible module is used to copy a file FROM the control node TO managed hosts?"
    hint="Look at the module names. One pushes content from the control node to remote hosts. Another pulls from remote to control. One manages file attributes only."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">copy</span> module transfers a file from the control node to a path on the managed host.\",
                    \"command\": \"- name: copy config file\\n  copy:\\n    src: files/httpd.conf\\n    dest: /etc/httpd/conf/httpd.conf\\n    owner: root\\n    mode: '0644'\"
                  },
                  {
                    \"instruction\": \"Do not confuse copy with fetch (remote → control) or file (manages attributes only, does not transfer content).\",
                    \"command\": \"# copy  = control node  → managed host\\n# fetch = managed host  → control node\\n# file  = set owner/mode/state, no transfer\"
                  }
                ]"
    answer_a="file"
    answer_b="fetch"
    answer_c="template"
    answer_d="copy"  # Correct answer
    ;;
  "fr")
    question="Quel module Ansible est utilisé pour copier un fichier DEPUIS le nœud de contrôle VERS les hôtes gérés ?"
    hint="Regardez les noms des modules. L'un envoie du contenu du nœud de contrôle vers les hôtes distants. Un autre récupère depuis le distant vers le contrôle. Un autre ne gère que les attributs de fichiers."
    instructions="[
                  {
                    \"instruction\": \"Le module <span class=\\\"bold-green-text\\\">copy</span> transfère un fichier du nœud de contrôle vers un chemin sur l'hôte géré.\",
                    \"command\": \"- name: copier le fichier de config\\n  copy:\\n    src: files/httpd.conf\\n    dest: /etc/httpd/conf/httpd.conf\\n    owner: root\\n    mode: '0644'\"
                  },
                  {
                    \"instruction\": \"Ne pas confondre copy avec fetch (distant → contrôle) ou file (gère uniquement les attributs, sans transfert de contenu).\",
                    \"command\": \"# copy  = nœud de contrôle → hôte géré\\n# fetch = hôte géré       → nœud de contrôle\\n# file  = définit owner/mode/state, pas de transfert\"
                  }
                ]"
    answer_a="file"
    answer_b="fetch"
    answer_c="template"
    answer_d="copy"  # Correct answer
    ;;
  *)
    question="Which Ansible module is used to copy a file FROM the control node TO managed hosts?"
    hint="Look at the module names. One pushes content from the control node to remote hosts. Another pulls from remote to control. One manages file attributes only."
    instructions="[
                  {
                    \"instruction\": \"The <span class=\\\"bold-green-text\\\">copy</span> module transfers a file from the control node to a path on the managed host.\",
                    \"command\": \"- name: copy config file\\n  copy:\\n    src: files/httpd.conf\\n    dest: /etc/httpd/conf/httpd.conf\\n    owner: root\\n    mode: '0644'\"
                  },
                  {
                    \"instruction\": \"Do not confuse copy with fetch (remote → control) or file (manages attributes only, does not transfer content).\",
                    \"command\": \"# copy  = control node  → managed host\\n# fetch = managed host  → control node\\n# file  = set owner/mode/state, no transfer\"
                  }
                ]"
    answer_a="file"
    answer_b="fetch"
    answer_c="template"
    answer_d="copy"  # Correct answer
    ;;
esac

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers to avoid predictable order
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the display JSON
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": {
    '"$shuffled_answers"'
  },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$answer_d"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
