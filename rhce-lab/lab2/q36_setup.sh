#!/bin/bash
# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  # Enable debugging: -e (exit on error), -o xtrace (show commands), -u (undefined vars are errors), -x (trace commands)
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

# Define the question, hint, instructions, and answers based on the language
case "$lang" in
  "en")
    question="What is the primary programming language used to develop Ansible?"
    hint="Consider the language that powers Ansible’s core functionality and its playbooks ..."
    instructions="[
                  {
                    \"instruction\": \"Think about the language that Ansible relies on for its execution and configuration files. The correct answer is: Ansible is primarily developed in Python.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible is primarily developed in Java."
    answer_b="Ansible is primarily developed in Python."  # Correct answer
    answer_c="Ansible is primarily developed in Ruby."
    answer_d="Ansible is primarily developed in C++."
    ;;
  "fr")
    question="Quel est le langage de programmation principal utilisé pour développer Ansible ?"
    hint="Considérez le langage qui alimente les fonctionnalités principales d'Ansible et ses playbooks ..."
    instructions="[
                  {
                    \"instruction\": \"Pensez au langage sur lequel Ansible s'appuie pour son exécution et ses fichiers de configuration. La réponse correcte est : Ansible est principalement développé en Python.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible est principalement développé en Java."
    answer_b="Ansible est principalement développé en Python."  # Réponse correcte
    answer_c="Ansible est principalement développé en Ruby."
    answer_d="Ansible est principalement développé en C++."
    ;;
  "de")
    question="Welche Programmiersprache wird hauptsächlich zur Entwicklung von Ansible verwendet?"
    hint="Überlegen Sie, welche Sprache die Kernfunktionalität von Ansible und seine Playbooks antreibt ..."
    instructions="[
                  {
                    \"instruction\": \"Denken Sie an die Sprache, auf die sich Ansible für seine Ausführung und Konfigurationsdateien stützt. Die richtige Antwort lautet: Ansible wird hauptsächlich in Python entwickelt.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible wird hauptsächlich in Java entwickelt."
    answer_b="Ansible wird hauptsächlich in Python entwickelt."  # Richtige Antwort
    answer_c="Ansible wird hauptsächlich in Ruby entwickelt."
    answer_d="Ansible wird hauptsächlich in C++ entwickelt."
    ;;
  "it")
    question="Qual è il linguaggio di programmazione principale utilizzato per sviluppare Ansible?"
    hint="Considera il linguaggio che alimenta le funzionalità principali di Ansible e i suoi playbook ..."
    instructions="[
                  {
                    \"instruction\": \"Pensa al linguaggio su cui Ansible si basa per la sua esecuzione e i file di configurazione. La risposta corretta è: Ansible è principalmente sviluppato in Python.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible è principalmente sviluppato in Java."
    answer_b="Ansible è principalmente sviluppato in Python."  # Risposta corretta
    answer_c="Ansible è principalmente sviluppato in Ruby."
    answer_d="Ansible è principalmente sviluppato in C++."
    ;;
  "es")
    question="¿Cuál es el lenguaje de programación principal utilizado para desarrollar Ansible?"
    hint="Considera el lenguaje que impulsa la funcionalidad principal de Ansible y sus playbooks ..."
    instructions="[
                  {
                    \"instruction\": \"Piensa en el lenguaje en el que Ansible se basa para su ejecución y archivos de configuración. La respuesta correcta es: Ansible está principalmente desarrollado en Python.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible está principalmente desarrollado en Java."
    answer_b="Ansible está principalmente desarrollado en Python."  # Respuesta correcta
    answer_c="Ansible está principalmente desarrollado en Ruby."
    answer_d="Ansible está principalmente desarrollado en C++."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the primary programming language used to develop Ansible?"
    hint="Consider the language that powers Ansible’s core functionality and its playbooks ..."
    instructions="[
                  {
                    \"instruction\": \"Think about the language that Ansible relies on for its execution and configuration files. The correct answer is: Ansible is primarily developed in Python.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Ansible is primarily developed in Java."
    answer_b="Ansible is primarily developed in Python."  # Correct answer
    answer_c="Ansible is primarily developed in Ruby."
    answer_d="Ansible is primarily developed in C++."
    ;;
esac

# Put answers in an array
answers=("\"answer_a\":\"$answer_a\"" "\"answer_b\":\"$answer_b\"" "\"answer_c\":\"$answer_c\"" "\"answer_d\":\"$answer_d\"")

# Shuffle the answers and format them as a valid JSON object
shuffled_answers=$(printf "%s\n" "${answers[@]}" | shuf | paste -sd,)

# Build the display JSON
display='{
  "question": "'"$question"'",
  "type": "multi",
  "answers": { '"$shuffled_answers"' },
  "hint": "'"$hint"'",
  "instructions": '"$instructions"',
  "solution": "'"$answer_b"'",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}'

# Use jq to pretty print the JSON (optional)
echo "$display" | jq .