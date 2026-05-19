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
    question="Who created Ansible and in what year was it first released?"
    hint="Think about the origins of Ansible and its connection to automation tools ..."
    instructions="[
                  {
                    \"instruction\": \"Consider the history of automation tools and their developers. The correct answer is: Michael DeHaan created Ansible, and it was first released in 2012.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Linus Torvalds created Ansible, and it was first released in 2005."
    answer_b="Michael DeHaan created Ansible, and it was first released in 2012."  # Correct answer
    answer_c="Guido van Rossum created Ansible, and it was first released in 1991."
    answer_d="Mark Shuttleworth created Ansible, and it was first released in 2004."
    ;;
  "fr")
    question="Qui a créé Ansible et en quelle année a-t-il été publié pour la première fois ?"
    hint="Pensez aux origines d'Ansible et à son lien avec les outils d'automatisation ..."
    instructions="[
                  {
                    \"instruction\": \"Réfléchissez à l'histoire des outils d'automatisation et à leurs développeurs. La réponse correcte est : Michael DeHaan a créé Ansible, et il a été publié pour la première fois en 2012.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Linus Torvalds a créé Ansible, et il a été publié pour la première fois en 2005."
    answer_b="Michael DeHaan a créé Ansible, et il a été publié pour la première fois en 2012."  # Réponse correcte
    answer_c="Guido van Rossum a créé Ansible, et il a été publié pour la première fois en 1991."
    answer_d="Mark Shuttleworth a créé Ansible, et il a été publié pour la première fois en 2004."
    ;;
  "de")
    question="Wer hat Ansible erschaffen und in welchem Jahr wurde es erstmals veröffentlicht?"
    hint="Überlegen Sie sich die Ursprünge von Ansible und seine Verbindung zu Automatisierungswerkzeugen ..."
    instructions="[
                  {
                    \"instruction\": \"Betrachten Sie die Geschichte der Automatisierungswerkzeuge und ihrer Entwickler. Die richtige Antwort lautet: Michael DeHaan hat Ansible erschaffen, und es wurde erstmals 2012 veröffentlicht.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Linus Torvalds hat Ansible erschaffen, und es wurde erstmals 2005 veröffentlicht."
    answer_b="Michael DeHaan hat Ansible erschaffen, und es wurde erstmals 2012 veröffentlicht."  # Richtige Antwort
    answer_c="Guido van Rossum hat Ansible erschaffen, und es wurde erstmals 1991 veröffentlicht."
    answer_d="Mark Shuttleworth hat Ansible erschaffen, und es wurde erstmals 2004 veröffentlicht."
    ;;
  "it")
    question="Chi ha creato Ansible e in quale anno è stato rilasciato per la prima volta?"
    hint="Pensa alle origini di Ansible e alla sua connessione con gli strumenti di automazione ..."
    instructions="[
                  {
                    \"instruction\": \"Considera la storia degli strumenti di automazione e i loro sviluppatori. La risposta corretta è: Michael DeHaan ha creato Ansible, ed è stato rilasciato per la prima volta nel 2012.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Linus Torvalds ha creato Ansible, ed è stato rilasciato per la prima volta nel 2005."
    answer_b="Michael DeHaan ha creato Ansible, ed è stato rilasciato per la prima volta nel 2012."  # Risposta corretta
    answer_c="Guido van Rossum ha creato Ansible, ed è stato rilasciato per la prima volta nel 1991."
    answer_d="Mark Shuttleworth ha creato Ansible, ed è stato rilasciato per la prima volta nel 2004."
    ;;
  "es")
    question="¿Quién creó Ansible y en qué año fue lanzado por primera vez?"
    hint="Piensa en los orígenes de Ansible y su conexión con herramientas de automatización ..."
    instructions="[
                  {
                    \"instruction\": \"Considera la historia de las herramientas de automatización y sus desarrolladores. La respuesta correcta es: Michael DeHaan creó Ansible, y fue lanzado por primera vez en 2012.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Linus Torvalds creó Ansible, y fue lanzado por primera vez en 2005."
    answer_b="Michael DeHaan creó Ansible, y fue lanzado por primera vez en 2012."  # Respuesta correcta
    answer_c="Guido van Rossum creó Ansible, y fue lanzado por primera vez en 1991."
    answer_d="Mark Shuttleworth creó Ansible, y fue lanzado por primera vez en 2004."
    ;;
  *)
    # Default to English if the language is not supported
    question="Who created Ansible and in what year was it first released?"
    hint="Think about the origins of Ansible and its connection to automation tools ..."
    instructions="[
                  {
                    \"instruction\": \"Consider the history of automation tools and their developers. The correct answer is: Michael DeHaan created Ansible, and it was first released in 2012.\",
                    \"command\": \"\"
                  }
                ]"
    answer_a="Linus Torvalds created Ansible, and it was first released in 2005."
    answer_b="Michael DeHaan created Ansible, and it was first released in 2012."  # Correct answer
    answer_c="Guido van Rossum created Ansible, and it was first released in 1991."
    answer_d="Mark Shuttleworth created Ansible, and it was first released in 2004."
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