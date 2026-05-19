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
    question="How does Ansible handle variable precedence with 'vars' and 'set_fact'?"
    hint="Consider how dynamically defined variables override static ones."
    instructions="[
                  {
                    \"instruction\": \"Variables defined using <span class=\\\"bold-green-text\\\">set_fact</span> have a higher precedence than those defined using <span class=\\\"bold-green-text\\\">vars</span>.\",
                    \"command\": \"#Use 'set_fact' to dynamically define variables during playbook execution.\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">vars</span> defines static variables that are overridden by dynamically defined variables.\",
                    \"command\": \"#set_fact: my_dynamic_var='value'\"
                  }
                ]"
    answer_a="Variables in 'vars' have the highest precedence."
    answer_b="Variables defined with 'set_fact' override 'vars'."  # Correct answer
    answer_c="Variables in 'vars' and 'set_fact' have equal precedence."
    answer_d="Ansible raises a conflict when both are defined."
    ;;
  "fr")
    question="Comment Ansible gère-t-il la priorité des variables avec 'vars' et 'set_fact' ?"
    hint="Réfléchissez à la manière dont les variables dynamiques remplacent les variables statiques."
    instructions="[
                  {
                    \"instruction\": \"Les variables définies avec <span class=\\\"bold-green-text\\\">set_fact</span> ont une priorité plus élevée que celles définies avec <span class=\\\"bold-green-text\\\">vars</span>.\",
                    \"command\": \"#Utilisez 'set_fact' pour définir dynamiquement des variables pendant l'exécution du playbook.\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">vars</span> définit des variables statiques qui sont remplacées par des variables dynamiques.\",
                    \"command\": \"#set_fact: my_dynamic_var='value'\"
                  }
                ]"
    answer_a="Les variables dans 'vars' ont la priorité la plus élevée."
    answer_b="Les variables définies avec 'set_fact' remplacent 'vars'."  # Correct answer
    answer_c="Les variables dans 'vars' et 'set_fact' ont une priorité égale."
    answer_d="Ansible signale un conflit lorsque les deux sont définies."
    ;;
  "es")
    question="¿Cómo maneja Ansible la precedencia de variables con 'vars' y 'set_fact'?"
    hint="Piensa en cómo las variables definidas dinámicamente reemplazan a las estáticas."
    instructions="[
                  {
                    \"instruction\": \"Las variables definidas con <span class=\\\"bold-green-text\\\">set_fact</span> tienen una mayor precedencia que las definidas con <span class=\\\"bold-green-text\\\">vars</span>.\",
                    \"command\": \"#Usa 'set_fact' para definir variables dinámicamente durante la ejecución del playbook.\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">vars</span> define variables estáticas que son reemplazadas por variables dinámicas.\",
                    \"command\": \"#set_fact: my_dynamic_var='value'\"
                  }
                ]"
    answer_a="Las variables en 'vars' tienen la precedencia más alta."
    answer_b="Las variables definidas con 'set_fact' reemplazan a 'vars'."  # Correct answer
    answer_c="Las variables en 'vars' y 'set_fact' tienen igual precedencia."
    answer_d="Ansible genera un conflicto cuando ambas están definidas."
    ;;
  "it")
    question="Come gestisce Ansible la precedenza delle variabili con 'vars' e 'set_fact'?"
    hint="Considera come le variabili definite dinamicamente sostituiscono quelle statiche."
    instructions="[
                  {
                    \"instruction\": \"Le variabili definite con <span class=\\\"bold-green-text\\\">set_fact</span> hanno una precedenza maggiore rispetto a quelle definite con <span class=\\\"bold-green-text\\\">vars</span>.\",
                    \"command\": \"#Usa 'set_fact' per definire dinamicamente variabili durante l'esecuzione del playbook.\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">vars</span> definisce variabili statiche che vengono sostituite da variabili dinamiche.\",
                    \"command\": \"#set_fact: my_dynamic_var='value'\"
                  }
                ]"
    answer_a="Le variabili in 'vars' hanno la precedenza più alta."
    answer_b="Le variabili definite con 'set_fact' sostituiscono 'vars'."  # Correct answer
    answer_c="Le variabili in 'vars' e 'set_fact' hanno precedenza uguale."
    answer_d="Ansible segnala un conflitto quando entrambe sono definite."
    ;;
  "de")
    question="Wie handhabt Ansible die Priorität von Variablen mit 'vars' und 'set_fact'?"
    hint="Denken Sie daran, wie dynamisch definierte Variablen statische ersetzen."
    instructions="[
                  {
                    \"instruction\": \"Variablen, die mit <span class=\\\"bold-green-text\\\">set_fact</span> definiert werden, haben eine höhere Priorität als solche, die mit <span class=\\\"bold-green-text\\\">vars</span> definiert werden.\",
                    \"command\": \"#Verwenden Sie 'set_fact', um Variablen während der Ausführung des Playbooks dynamisch zu definieren.\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">vars</span> definiert statische Variablen, die von dynamisch definierten Variablen überschrieben werden.\",
                    \"command\": \"#set_fact: my_dynamic_var='value'\"
                  }
                ]"
    answer_a="Variablen in 'vars' haben die höchste Priorität."
    answer_b="Mit 'set_fact' definierte Variablen überschreiben 'vars'."  # Correct answer
    answer_c="Variablen in 'vars' und 'set_fact' haben die gleiche Priorität."
    answer_d="Ansible meldet einen Konflikt, wenn beide definiert sind."
    ;;
  *)
    # Default to English if the language is not supported
    question="How does Ansible handle variable precedence with 'vars' and 'set_fact'?"
    hint="Consider how dynamically defined variables override static ones."
    instructions="[
                  {
                    \"instruction\": \"Variables defined using <span class=\\\"bold-green-text\\\">set_fact</span> have a higher precedence than those defined using <span class=\\\"bold-green-text\\\">vars</span>.\",
                    \"command\": \"#Use 'set_fact' to dynamically define variables during playbook execution.\"
                  },
                  {
                    \"instruction\": \"<span class=\\\"bold-green-text\\\">vars</span> defines static variables that are overridden by dynamically defined variables.\",
                    \"command\": \"#set_fact: my_dynamic_var='value'\"
                  }
                ]"
    answer_a="Variables in 'vars' have the highest precedence."
    answer_b="Variables defined with 'set_fact' override 'vars'."  # Correct answer
    answer_c="Variables in 'vars' and 'set_fact' have equal precedence."
    answer_d="Ansible raises a conflict when both are defined."
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
  "platform_required": "server",
  "os_required": "ubuntu"
}'

# Pretty print the JSON output (optional)
echo "$display" | jq .
