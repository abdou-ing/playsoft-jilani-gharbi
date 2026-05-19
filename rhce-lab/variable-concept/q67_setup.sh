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
    question="When MUST a variable reference be wrapped in double quotes inside an Ansible task?"
    hint="YAML treats any value that starts with { as a dictionary literal. Think about what that means when a value begins with the Jinja2 template marker."
    instructions="[
                  {
                    \"instruction\": \"YAML parses a value starting with <span class=\\\"bold-green-text\\\">{{</span> as a dictionary, which causes a parse error. Double quotes force string interpretation.\",
                    \"command\": \"# WRONG - YAML parse error (value starts with {{):\\nname: {{ my_var }}\\n\\n# CORRECT - quotes prevent the YAML parse error:\\nname: \\\"{{ my_var }}\\\"\"
                  },
                  {
                    \"instruction\": \"When the variable is NOT the first element in the value, double quotes are not required.\",
                    \"command\": \"# No quotes needed (variable is not the first item):\\ndescription: The package {{ my_var }} is installed\\n\\n# Quotes still required when value starts with variable:\\nfull_path: \\\"{{ base_dir }}/config.yml\\\"\"
                  }
                ]"
    answer_a="Always, double quotes are mandatory around every variable reference"
    answer_b="Never, Ansible handles quoting of variables automatically"
    answer_c="Only when the variable is used inside the debug module"
    answer_d="When the value starts with {{ (the variable is the first item in the value)"  # Correct answer
    ;;
  "fr")
    question="QUAND une référence de variable doit-elle OBLIGATOIREMENT être entourée de guillemets doubles dans une tâche Ansible ?"
    hint="YAML traite toute valeur commençant par { comme un dictionnaire littéral. Pensez à ce que cela implique quand une valeur commence par le marqueur de template Jinja2."
    instructions="[
                  {
                    \"instruction\": \"YAML analyse une valeur commençant par <span class=\\\"bold-green-text\\\">{{</span> comme un dictionnaire, ce qui provoque une erreur d'analyse. Les guillemets doubles forcent l'interprétation comme chaîne.\",
                    \"command\": \"# INCORRECT - erreur d'analyse YAML (valeur commence par {{) :\\nname: {{ my_var }}\\n\\n# CORRECT - les guillemets évitent l'erreur d'analyse YAML :\\nname: \\\"{{ my_var }}\\\"\"
                  },
                  {
                    \"instruction\": \"Quand la variable N'EST PAS le premier élément de la valeur, les guillemets doubles ne sont pas nécessaires.\",
                    \"command\": \"# Pas de guillemets nécessaires (variable pas en premier) :\\ndescription: Le paquet {{ my_var }} est installé\\n\\n# Guillemets requis quand la valeur commence par la variable :\\nfull_path: \\\"{{ base_dir }}/config.yml\\\"\"
                  }
                ]"
    answer_a="Toujours, les guillemets doubles sont obligatoires autour de chaque référence de variable"
    answer_b="Jamais, Ansible gère automatiquement les guillemets des variables"
    answer_c="Uniquement quand la variable est utilisée dans le module debug"
    answer_d="Quand la valeur commence par {{ (la variable est le premier élément de la valeur)"  # Correct answer
    ;;
  *)
    question="When MUST a variable reference be wrapped in double quotes inside an Ansible task?"
    hint="YAML treats any value that starts with { as a dictionary literal. Think about what that means when a value begins with the Jinja2 template marker."
    instructions="[
                  {
                    \"instruction\": \"YAML parses a value starting with <span class=\\\"bold-green-text\\\">{{</span> as a dictionary, which causes a parse error. Double quotes force string interpretation.\",
                    \"command\": \"# WRONG - YAML parse error (value starts with {{):\\nname: {{ my_var }}\\n\\n# CORRECT - quotes prevent the YAML parse error:\\nname: \\\"{{ my_var }}\\\"\"
                  },
                  {
                    \"instruction\": \"When the variable is NOT the first element in the value, double quotes are not required.\",
                    \"command\": \"# No quotes needed (variable is not the first item):\\ndescription: The package {{ my_var }} is installed\\n\\n# Quotes still required when value starts with variable:\\nfull_path: \\\"{{ base_dir }}/config.yml\\\"\"
                  }
                ]"
    answer_a="Always, double quotes are mandatory around every variable reference"
    answer_b="Never, Ansible handles quoting of variables automatically"
    answer_c="Only when the variable is used inside the debug module"
    answer_d="When the value starts with {{ (the variable is the first item in the value)"  # Correct answer
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
