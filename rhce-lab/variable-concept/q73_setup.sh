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
    question="Which command lets you READ the contents of an ansible-vault encrypted file without permanently decrypting it on disk?"
    hint="Try creating a small vault file and test each command. One sub-command opens the file in read-only mode without writing a decrypted copy to disk."
    instructions="[
                  {
                    \"instruction\": \"Create a test vault file, then try the correct command to read it safely.\",
                    \"command\": \"# Create a vault file (password: test123):\\nansible-vault create secrets.yaml\\n\\n# Now try reading it without decrypting to disk:\\nansible-vault view secrets.yaml\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible-vault view</span> prompts for the password and displays the content — the file stays encrypted on disk. <span class=\\\"bold-green-text\\\">ansible-vault decrypt</span> writes a permanently decrypted copy.\",
                    \"command\": \"# Compare: decrypt writes plaintext to disk (dangerous):\\nansible-vault decrypt secrets.yaml\\n\\n# view shows content safely without touching the file:\\nansible-vault view secrets.yaml\"
                  }
                ]"
    answer_a="ansible-vault decrypt secrets.yaml"
    answer_b="ansible-vault view secrets.yaml"  # Correct answer
    answer_c="ansible-vault read secrets.yaml"
    answer_d="ansible-vault show secrets.yaml"
    ;;
  "fr")
    question="Quelle commande permet de LIRE le contenu d'un fichier chiffré par ansible-vault sans le déchiffrer définitivement sur le disque ?"
    hint="Essayez de créer un petit fichier vault et testez chaque commande. Une sous-commande ouvre le fichier en lecture seule sans écrire de copie déchiffrée sur le disque."
    instructions="[
                  {
                    \"instruction\": \"Créez un fichier vault de test, puis essayez la bonne commande pour le lire en toute sécurité.\",
                    \"command\": \"# Créer un fichier vault (mot de passe : test123) :\\nansible-vault create secrets.yaml\\n\\n# Lire le fichier sans le déchiffrer sur le disque :\\nansible-vault view secrets.yaml\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible-vault view</span> demande le mot de passe et affiche le contenu — le fichier reste chiffré sur le disque. <span class=\\\"bold-green-text\\\">ansible-vault decrypt</span> écrit une copie définitivement déchiffrée.\",
                    \"command\": \"# Comparaison : decrypt écrit le texte clair sur le disque (dangereux) :\\nansible-vault decrypt secrets.yaml\\n\\n# view affiche le contenu en toute sécurité sans modifier le fichier :\\nansible-vault view secrets.yaml\"
                  }
                ]"
    answer_a="ansible-vault decrypt secrets.yaml"
    answer_b="ansible-vault view secrets.yaml"  # Correct answer
    answer_c="ansible-vault read secrets.yaml"
    answer_d="ansible-vault show secrets.yaml"
    ;;
  *)
    question="Which command lets you READ the contents of an ansible-vault encrypted file without permanently decrypting it on disk?"
    hint="Try creating a small vault file and test each command. One sub-command opens the file in read-only mode without writing a decrypted copy to disk."
    instructions="[
                  {
                    \"instruction\": \"Create a test vault file, then try the correct command to read it safely.\",
                    \"command\": \"# Create a vault file (password: test123):\\nansible-vault create secrets.yaml\\n\\n# Now try reading it without decrypting to disk:\\nansible-vault view secrets.yaml\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">ansible-vault view</span> prompts for the password and displays the content — the file stays encrypted on disk. <span class=\\\"bold-green-text\\\">ansible-vault decrypt</span> writes a permanently decrypted copy.\",
                    \"command\": \"# Compare: decrypt writes plaintext to disk (dangerous):\\nansible-vault decrypt secrets.yaml\\n\\n# view shows content safely without touching the file:\\nansible-vault view secrets.yaml\"
                  }
                ]"
    answer_a="ansible-vault decrypt secrets.yaml"
    answer_b="ansible-vault view secrets.yaml"  # Correct answer
    answer_c="ansible-vault read secrets.yaml"
    answer_d="ansible-vault show secrets.yaml"
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
  "solution": "'"$answer_b"'",
  "plateforme_required": "container",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
