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
    question="What is the precedence order of configuration sources in Ansible?"
    hint="Think about how Ansible allows overriding configurations from multiple sources."
    instructions="[
                  {
                    \"instruction\": \"Ansible's configuration precedence is as follows: 1) Command-line options, 2) Environment variables, 3) 'ansible.cfg' in the current directory, 4) '.ansible.cfg' in the home directory, 5) '/etc/ansible/ansible.cfg'\",
                    \"command\": \"ansible-config view\"
                  },
                  {
                    \"instruction\": \"This order ensures flexibility and control over configuration settings, allowing higher-priority sources to override lower-priority ones\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    answer_a="Environment variables > Command-line options > ansible.cfg > Global config."
    answer_b="ansible.cfg > Command-line options > Global config > Environment variables."
    answer_c="Command-line options > Environment variables > Current directory ansible.cfg > Home directory ansible.cfg > Global config."  # Correct answer
    answer_d="Global config > Environment variables > ansible.cfg > Command-line options."
    ;;
  "fr")
    question="Quel est l'ordre de priorité des sources de configuration dans Ansible ?"
    hint="Réfléchissez à la manière dont Ansible permet de remplacer les configurations à partir de plusieurs sources."
    instructions="[
                  {
                    \"instruction\": \"L'ordre de priorité des configurations dans Ansible est le suivant : 1) Options de ligne de commande, 2) Variables d'environnement, 3) 'ansible.cfg' dans le répertoire courant, 4) '.ansible.cfg' dans le répertoire personnel, 5) '/etc/ansible/ansible.cfg'\",
                    \"command\": \"ansible-config view\"
                  },
                  {
                    \"instruction\": \"Cet ordre garantit une flexibilité et un contrôle sur les paramètres de configuration, permettant aux sources de priorité plus élevée de remplacer celles de priorité plus faible\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    answer_a="Variables d'environnement > Options de ligne de commande > ansible.cfg > Configuration globale."
    answer_b="ansible.cfg > Options de ligne de commande > Configuration globale > Variables d'environnement."
    answer_c="Options de ligne de commande > Variables d'environnement > ansible.cfg dans le répertoire courant > ansible.cfg dans le répertoire personnel > Configuration globale."  # Correct answer
    answer_d="Configuration globale > Variables d'environnement > ansible.cfg > Options de ligne de commande."
    ;;
  "de")
    question="Welche Reihenfolge hat die Priorität der Konfigurationsquellen in Ansible?"
    hint="Denken Sie darüber nach, wie Ansible das Überschreiben von Konfigurationen aus mehreren Quellen ermöglicht."
    instructions="[
                  {
                    \"instruction\": \"Die Priorität der Konfigurationen in Ansible ist wie folgt: 1) Befehlszeilenoptionen, 2) Umgebungsvariablen, 3) 'ansible.cfg' im aktuellen Verzeichnis, 4) '.ansible.cfg' im Home-Verzeichnis, 5) '/etc/ansible/ansible.cfg'\",
                    \"command\": \"ansible-config view\"
                  },
                  {
                    \"instruction\": \"Diese Reihenfolge gewährleistet Flexibilität und Kontrolle über die Konfigurationseinstellungen, sodass höher priorisierte Quellen niedriger priorisierte überschreiben können\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    answer_a="Umgebungsvariablen > Befehlszeilenoptionen > ansible.cfg > Globale Konfiguration."
    answer_b="ansible.cfg > Befehlszeilenoptionen > Globale Konfiguration > Umgebungsvariablen."
    answer_c="Befehlszeilenoptionen > Umgebungsvariablen > ansible.cfg im aktuellen Verzeichnis > ansible.cfg im Home-Verzeichnis > Globale Konfiguration."  # Correct answer
    answer_d="Globale Konfiguration > Umgebungsvariablen > ansible.cfg > Befehlszeilenoptionen."
    ;;
  "es")
    question="¿Cuál es el orden de precedencia de las fuentes de configuración en Ansible?"
    hint="Piensa en cómo Ansible permite anular configuraciones desde múltiples fuentes."
    instructions="[
                  {
                    \"instruction\": \"El orden de precedencia de las configuraciones en Ansible es el siguiente: 1) Opciones de línea de comandos, 2) Variables de entorno, 3) 'ansible.cfg' en el directorio actual, 4) '.ansible.cfg' en el directorio personal, 5) '/etc/ansible/ansible.cfg'\",
                    \"command\": \"ansible-config view\"
                  },
                  {
                    \"instruction\": \"Este orden garantiza flexibilidad y control sobre los ajustes de configuración, permitiendo que las fuentes de mayor prioridad anulen las de menor prioridad\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    answer_a="Variables de entorno > Opciones de línea de comandos > ansible.cfg > Configuración global."
    answer_b="ansible.cfg > Opciones de línea de comandos > Configuración global > Variables de entorno."
    answer_c="Opciones de línea de comandos > Variables de entorno > ansible.cfg en el directorio actual > ansible.cfg en el directorio personal > Configuración global."  # Correct answer
    answer_d="Configuración global > Variables de entorno > ansible.cfg > Opciones de línea de comandos."
    ;;
  "it")
    question="Qual è l'ordine di precedenza delle fonti di configurazione in Ansible?"
    hint="Pensa a come Ansible consente di sovrascrivere le configurazioni da più fonti."
    instructions="[
                  {
                    \"instruction\": \"L'ordine di precedenza delle configurazioni in Ansible è il seguente: 1) Opzioni della riga di comando, 2) Variabili d'ambiente, 3) 'ansible.cfg' nella directory corrente, 4) '.ansible.cfg' nella directory home, 5) '/etc/ansible/ansible.cfg'\",
                    \"command\": \"ansible-config view\"
                  },
                  {
                    \"instruction\": \"Questo ordine garantisce flessibilità e controllo sulle impostazioni di configurazione, consentendo alle fonti di priorità più alta di sovrascrivere quelle di priorità più bassa\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    answer_a="Variabili d'ambiente > Opzioni della riga di comando > ansible.cfg > Configurazione globale."
    answer_b="ansible.cfg > Opzioni della riga di comando > Configurazione globale > Variabili d'ambiente."
    answer_c="Opzioni della riga di comando > Variabili d'ambiente > ansible.cfg nella directory corrente > ansible.cfg nella directory home > Configurazione globale."  # Correct answer
    answer_d="Configurazione globale > Variabili d'ambiente > ansible.cfg > Opzioni della riga di comando."
    ;;
  *)
    # Default to English if the language is not supported
    question="What is the precedence order of configuration sources in Ansible?"
    hint="Think about how Ansible allows overriding configurations from multiple sources."
    instructions="[
                  {
                    \"instruction\": \"Ansible's configuration precedence is as follows: 1) Command-line options, 2) Environment variables, 3) 'ansible.cfg' in the current directory, 4) '.ansible.cfg' in the home directory, 5) '/etc/ansible/ansible.cfg'\",
                    \"command\": \"ansible-config view\"
                  },
                  {
                    \"instruction\": \"This order ensures flexibility and control over configuration settings, allowing higher-priority sources to override lower-priority ones\",
                    \"command\": \"ansible --version\"
                  }
                ]"
    answer_a="Environment variables > Command-line options > ansible.cfg > Global config."
    answer_b="ansible.cfg > Command-line options > Global config > Environment variables."
    answer_c="Command-line options > Environment variables > Current directory ansible.cfg > Home directory ansible.cfg > Global config."  # Correct answer
    answer_d="Global config > Environment variables > ansible.cfg > Command-line options."
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