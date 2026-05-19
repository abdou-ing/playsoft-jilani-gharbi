#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  # Shift arguments to ignore "debug" and pass the rest to the script
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="What is the purpose of the 'ansible-vault' command?"
    hint="Think about how sensitive information, such as passwords, can be securely managed in Ansible."
    instructions="[
                  {
                    \"instruction\": \"The 'ansible-vault' command is used to encrypt sensitive data, such as passwords or API keys, for secure storage\",
                    \"command\": \"ansible-vault encrypt secret.yml\"
                  },
                  {
                    \"instruction\": \"It can also decrypt the data when needed, ensuring secure handling of confidential information in playbooks and inventories\",
                    \"command\": \"ansible-vault decrypt secret.yml\"
                  }
                ]"
    answer_a="It encrypts and decrypts sensitive data for secure use in playbooks."  # Correct answer
    answer_b="It validates playbook syntax before execution."
    answer_c="It initializes Ansible configurations for secure connections."
    answer_d="It updates the inventory file with encrypted host details."
    ;;
  "fr")
    question="Quel est l'objectif de la commande 'ansible-vault' ?"
    hint="Réfléchissez à la manière dont les informations sensibles, telles que les mots de passe, peuvent être gérées de manière sécurisée dans Ansible."
    instructions="[
                  {
                    \"instruction\": \"La commande 'ansible-vault' est utilisée pour chiffrer des données sensibles, telles que des mots de passe ou des clés API, pour un stockage sécurisé\",
                    \"command\": \"ansible-vault encrypt secret.yml\"
                  },
                  {
                    \"instruction\": \"Elle peut également déchiffrer les données lorsque cela est nécessaire, garantissant une gestion sécurisée des informations confidentielles dans les playbooks et les inventaires\",
                    \"command\": \"ansible-vault decrypt secret.yml\"
                  }
                ]"
    answer_a="Elle chiffre et déchiffre des données sensibles pour une utilisation sécurisée dans les playbooks."  # Correct answer
    answer_b="Elle valide la syntaxe des playbooks avant leur exécution."
    answer_c="Elle initialise les configurations Ansible pour des connexions sécurisées."
    answer_d="Elle met à jour le fichier d'inventaire avec des détails d'hôtes chiffrés."
    ;;
  "de")
    question="Was ist der Zweck des Befehls 'ansible-vault'?"
    hint="Denken Sie darüber nach, wie sensible Informationen wie Passwörter in Ansible sicher verwaltet werden können."
    instructions="[
                  {
                    \"instruction\": \"Der Befehl 'ansible-vault' wird verwendet, um sensible Daten wie Passwörter oder API-Schlüssel für die sichere Speicherung zu verschlüsseln\",
                    \"command\": \"ansible-vault encrypt secret.yml\"
                  },
                  {
                    \"instruction\": \"Er kann die Daten bei Bedarf auch entschlüsseln, um einen sicheren Umgang mit vertraulichen Informationen in Playbooks und Inventaren zu gewährleisten\",
                    \"command\": \"ansible-vault decrypt secret.yml\"
                  }
                ]"
    answer_a="Er verschlüsselt und entschlüsselt sensible Daten für die sichere Verwendung in Playbooks."  # Correct answer
    answer_b="Er überprüft die Syntax von Playbooks vor der Ausführung."
    answer_c="Er initialisiert Ansible-Konfigurationen für sichere Verbindungen."
    answer_d="Er aktualisiert die Inventardatei mit verschlüsselten Host-Details."
    ;;
  "es")
    question="¿Cuál es el propósito del comando 'ansible-vault'?"
    hint="Piensa en cómo se pueden gestionar de forma segura en Ansible informaciones sensibles, como contraseñas."
    instructions="[
                  {
                    \"instruction\": \"El comando 'ansible-vault' se utiliza para cifrar datos sensibles, como contraseñas o claves API, para su almacenamiento seguro\",
                    \"command\": \"ansible-vault encrypt secret.yml\"
                  },
                  {
                    \"instruction\": \"También puede descifrar los datos cuando sea necesario, asegurando un manejo seguro de la información confidencial en los playbooks y los inventarios\",
                    \"command\": \"ansible-vault decrypt secret.yml\"
                  }
                ]"
    answer_a="Cifra y descifra datos sensibles para su uso seguro en los playbooks."  # Correct answer
    answer_b="Valida la sintaxis de los playbooks antes de su ejecución."
    answer_c="Inicializa configuraciones de Ansible para conexiones seguras."
    answer_d="Actualiza el archivo de inventario con detalles de hosts cifrados."
    ;;
  "it")
    question="Qual è lo scopo del comando 'ansible-vault'?"
    hint="Pensa a come le informazioni sensibili, come le password, possono essere gestite in modo sicuro in Ansible."
    instructions="[
                  {
                    \"instruction\": \"Il comando 'ansible-vault' viene utilizzato per crittografare dati sensibili, come password o chiavi API, per un archivio sicuro\",
                    \"command\": \"ansible-vault encrypt secret.yml\"
                  },
                  {
                    \"instruction\": \"Può anche decrittografare i dati quando necessario, garantendo una gestione sicura delle informazioni riservate nei playbook e negli inventari\",
                    \"command\": \"ansible-vault decrypt secret.yml\"
                  }
                ]"
    answer_a="Crittografa e decrittografa dati sensibili per un uso sicuro nei playbook."  # Correct answer
    answer_b="Convalida la sintassi dei playbook prima dell'esecuzione."
    answer_c="Inizializza le configurazioni di Ansible per connessioni sicure."
    answer_d="Aggiorna il file di inventario con dettagli degli host crittografati."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the 'ansible-vault' command?"
    hint="Think about how sensitive information, such as passwords, can be securely managed in Ansible."
    instructions="[
                  {
                    \"instruction\": \"The 'ansible-vault' command is used to encrypt sensitive data, such as passwords or API keys, for secure storage\",
                    \"command\": \"ansible-vault encrypt secret.yml\"
                  },
                  {
                    \"instruction\": \"It can also decrypt the data when needed, ensuring secure handling of confidential information in playbooks and inventories\",
                    \"command\": \"ansible-vault decrypt secret.yml\"
                  }
                ]"
    answer_a="It encrypts and decrypts sensitive data for secure use in playbooks."  # Correct answer
    answer_b="It validates playbook syntax before execution."
    answer_c="It initializes Ansible configurations for secure connections."
    answer_d="It updates the inventory file with encrypted host details."
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
  "solution": "'"$answer_a"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .