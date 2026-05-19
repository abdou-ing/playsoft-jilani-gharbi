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
    question="Which ansible-vault sub-command is used to change the password on an already-encrypted file?"
    hint="ansible-vault has several sub-commands. One of them is specifically designed for rotating the encryption password on an existing vault file without decrypting it first."
    instructions="[
                  {
                    \"instruction\": \"Use <span class=\\\"bold-green-text\\\">ansible-vault rekey</span> to change the password on an existing encrypted file.\",
                    \"command\": \"ansible-vault rekey secrets.yaml\\n# Prompts for: current vault password\\n# Prompts for: new vault password\\n# Prompts for: confirm new vault password\"
                  },
                  {
                    \"instruction\": \"All ansible-vault sub-commands at a glance.\",
                    \"command\": \"ansible-vault create   secret.yaml  # new encrypted file\\nansible-vault encrypt  secret.yaml  # encrypt existing file\\nansible-vault decrypt  secret.yaml  # decrypt to plaintext\\nansible-vault rekey    secret.yaml  # change the password\\nansible-vault view     secret.yaml  # view without decrypting\\nansible-vault edit     secret.yaml  # edit in place\"
                  }
                ]"
    answer_a="repass"
    answer_b="rekey"  # Correct answer
    answer_c="change-password"
    answer_d="update"
    ;;
  "fr")
    question="Quelle sous-commande ansible-vault permet de changer le mot de passe d'un fichier déjà chiffré ?"
    hint="ansible-vault dispose de plusieurs sous-commandes. L'une d'elles est spécifiquement conçue pour changer le mot de passe de chiffrement d'un fichier vault existant sans le déchiffrer au préalable."
    instructions="[
                  {
                    \"instruction\": \"Utilisez <span class=\\\"bold-green-text\\\">ansible-vault rekey</span> pour changer le mot de passe d'un fichier chiffré existant.\",
                    \"command\": \"ansible-vault rekey secrets.yaml\\n# Demande : mot de passe vault actuel\\n# Demande : nouveau mot de passe vault\\n# Demande : confirmer le nouveau mot de passe\"
                  },
                  {
                    \"instruction\": \"Toutes les sous-commandes ansible-vault en un coup d'oeil.\",
                    \"command\": \"ansible-vault create   secret.yaml  # nouveau fichier chiffré\\nansible-vault encrypt  secret.yaml  # chiffrer un fichier existant\\nansible-vault decrypt  secret.yaml  # déchiffrer en clair\\nansible-vault rekey    secret.yaml  # changer le mot de passe\\nansible-vault view     secret.yaml  # afficher sans déchiffrer\\nansible-vault edit     secret.yaml  # modifier en place\"
                  }
                ]"
    answer_a="repass"
    answer_b="rekey"  # Correct answer
    answer_c="change-password"
    answer_d="update"
    ;;
  *)
    question="Which ansible-vault sub-command is used to change the password on an already-encrypted file?"
    hint="ansible-vault has several sub-commands. One of them is specifically designed for rotating the encryption password on an existing vault file without decrypting it first."
    instructions="[
                  {
                    \"instruction\": \"Use <span class=\\\"bold-green-text\\\">ansible-vault rekey</span> to change the password on an existing encrypted file.\",
                    \"command\": \"ansible-vault rekey secrets.yaml\\n# Prompts for: current vault password\\n# Prompts for: new vault password\\n# Prompts for: confirm new vault password\"
                  },
                  {
                    \"instruction\": \"All ansible-vault sub-commands at a glance.\",
                    \"command\": \"ansible-vault create   secret.yaml  # new encrypted file\\nansible-vault encrypt  secret.yaml  # encrypt existing file\\nansible-vault decrypt  secret.yaml  # decrypt to plaintext\\nansible-vault rekey    secret.yaml  # change the password\\nansible-vault view     secret.yaml  # view without decrypting\\nansible-vault edit     secret.yaml  # edit in place\"
                  }
                ]"
    answer_a="repass"
    answer_b="rekey"  # Correct answer
    answer_c="change-password"
    answer_d="update"
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
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output
echo "$display" | jq .
