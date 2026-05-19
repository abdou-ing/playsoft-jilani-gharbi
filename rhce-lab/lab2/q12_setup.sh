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
    question="What is the purpose of the '--check' option in the 'ansible-playbook' command?"
    hint="Think about how you can preview changes without applying them."
    instructions="[
                  {
                    \"instruction\": \"The '--check' option runs a playbook in dry-run mode. It simulates the execution and shows the changes that would be made, without actually making them.\",
                    \"command\": \"ansible-playbook --check playbook.yml\"
                  },
                  {
                    \"instruction\": \"This is useful for testing playbooks before applying changes to production systems.\",
                    \"command\": \"ansible-playbook --check another-playbook.yml\"
                  }
                ]"
    answer_a="It checks the syntax of the playbook."
    answer_b="It executes the playbook without gathering facts."
    answer_c="It runs the playbook in dry-run mode, showing changes without applying them."  # Correct answer
    answer_d="It verifies the inventory file for managed nodes."
    ;;
  "fr")
    question="Quel est l'objectif de l'option '--check' dans la commande 'ansible-playbook' ?"
    hint="Réfléchissez à la manière de prévisualiser les changements sans les appliquer."
    instructions="[
                  {
                    \"instruction\": \"L'option '--check' exécute un playbook en mode dry-run. Elle simule l'exécution et montre les changements qui seraient apportés, sans les appliquer réellement.\",
                    \"command\": \"ansible-playbook --check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Cela est utile pour tester les playbooks avant d'appliquer des changements aux systèmes de production.\",
                    \"command\": \"ansible-playbook --check another-playbook.yml\"
                  }
                ]"
    answer_a="Elle vérifie la syntaxe du playbook."
    answer_b="Elle exécute le playbook sans collecter les faits."
    answer_c="Elle exécute le playbook en mode dry-run, montrant les changements sans les appliquer."  # Correct answer
    answer_d="Elle vérifie le fichier d'inventaire pour les nœuds gérés."
    ;;
  "es")
    question="¿Cuál es el propósito de la opción '--check' en el comando 'ansible-playbook'?"
    hint="Piensa en cómo puedes previsualizar cambios sin aplicarlos."
    instructions="[
                  {
                    \"instruction\": \"La opción '--check' ejecuta un playbook en modo dry-run. Simula la ejecución y muestra los cambios que se harían, sin aplicarlos realmente.\",
                    \"command\": \"ansible-playbook --check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Esto es útil para probar playbooks antes de aplicar cambios en sistemas de producción.\",
                    \"command\": \"ansible-playbook --check another-playbook.yml\"
                  }
                ]"
    answer_a="Verifica la sintaxis del playbook."
    answer_b="Ejecuta el playbook sin recopilar hechos."
    answer_c="Ejecuta el playbook en modo dry-run, mostrando cambios sin aplicarlos."  # Correct answer
    answer_d="Verifica el archivo de inventario para los nodos gestionados."
    ;;
   "it")
    question="Qual è lo scopo dell'opzione '--check' nel comando 'ansible-playbook'?"
    hint="Pensa a come puoi visualizzare in anteprima le modifiche senza applicarle."
    instructions="[
                  {
                    \"instruction\": \"L'opzione '--check' esegue un playbook in modalità di prova. Simula l'esecuzione e mostra le modifiche che verrebbero apportate, senza applicarle realmente.\",
                    \"command\": \"ansible-playbook --check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Questo è utile per testare i playbook prima di applicare modifiche ai sistemi di produzione.\",
                    \"command\": \"ansible-playbook --check another-playbook.yml\"
                  }
                ]"
    answer_a="Verifica la sintassi del playbook."
    answer_b="Esegue il playbook senza raccogliere i fatti."
    answer_c="Esegue il playbook in modalità di prova, mostrando le modifiche senza applicarle."  # Correct answer
    answer_d="Verifica il file di inventario per i nodi gestiti."
    ;;
  "de")
    question="Was ist der Zweck der Option '--check' im 'ansible-playbook'-Befehl?"
    hint="Denken Sie darüber nach, wie Sie Änderungen anzeigen können, ohne sie anzuwenden."
    instructions="[
                  {
                    \"instruction\": \"Die Option '--check' führt ein Playbook im Trockenlaufmodus aus. Es simuliert die Ausführung und zeigt die Änderungen, die vorgenommen würden, ohne sie tatsächlich anzuwenden.\",
                    \"command\": \"ansible-playbook --check playbook.yml\"
                  },
                  {
                    \"instruction\": \"Dies ist nützlich, um Playbooks zu testen, bevor Änderungen an Produktionssystemen vorgenommen werden.\",
                    \"command\": \"ansible-playbook --check another-playbook.yml\"
                  }
                ]"
    answer_a="Es überprüft die Syntax des Playbooks."
    answer_b="Es führt das Playbook ohne das Sammeln von Fakten aus."
    answer_c="Es führt das Playbook im Trockenlaufmodus aus und zeigt Änderungen, ohne sie anzuwenden."  # Correct answer
    answer_d="Es überprüft die Inventardatei für verwaltete Knoten."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the purpose of the '--check' option in the 'ansible-playbook' command?"
    hint="Think about how you can preview changes without applying them."
    instructions="[
                  {
                    \"instruction\": \"The '--check' option runs a playbook in dry-run mode. It simulates the execution and shows the changes that would be made, without actually making them.\",
                    \"command\": \"ansible-playbook --check playbook.yml\"
                  },
                  {
                    \"instruction\": \"This is useful for testing playbooks before applying changes to production systems.\",
                    \"command\": \"ansible-playbook --check another-playbook.yml\"
                  }
                ]"
    answer_a="It checks the syntax of the playbook."
    answer_b="It executes the playbook without gathering facts."
    answer_c="It runs the playbook in dry-run mode, showing changes without applying them."  # Correct answer
    answer_d="It verifies the inventory file for managed nodes."
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
  "solution": "'"$answer_c"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .