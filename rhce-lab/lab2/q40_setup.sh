#!/bin/bash

# Check if "debug" is passed as an argument
if [[ "$1" == "debug" ]]; then
  set -eoux
  shift
fi

# Language argument
lang="${1:-en}" # Default to English if no language is specified

project_dir="/home/ansible_user/ansible_variables_project"

# Create the project directory
if [[ ! -d "$project_dir" ]]; then
  mkdir "$project_dir"
  #echo "Directory $project_dir created."
fi

cd "$project_dir"

# Create a basic playbook with hardcoded values
cat <<EOF > playbook.yml
---
- name: Configure web server
  hosts: localhost
  tasks:
    - name: Install Apache
      ansible.builtin.apt:
        name: apache2
        state: present
    - name: Copy index.html
      ansible.builtin.copy:
        content: "Welcome to my web server"
        dest: "/var/www/html/index.html"
EOF

case "$lang" in
  "en")
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file that installs Apache and copies a hardcoded 'index.html' file. Following Ansible best practices, refactor the playbook to use variables named 'web_package' and 'html_content' for the package name ('apache2') and the HTML content ('Welcome to my web server') to improve flexibility and maintainability."
    hint="Define variables named 'web_package' and 'html_content' in the playbook under a 'vars' section and reference them in the tasks using Jinja2 syntax (e.g., {{ web_package }} and {{ html_content }})."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to include variables 'web_package' and 'html_content' and use them in tasks:\",
        \"command\": \"echo -e '---\\n- name: Configure web server\\n  hosts: localhost\\n  vars:\\n    web_package: apache2\\n    html_content: \\\"Welcome to my web server\\\"\\n  tasks:\\n    - name: Install Apache\\n      ansible.builtin.apt:\\n        name: \\\"{{ web_package }}\\\"\\n        state: present\\n    - name: Copy index.html\\n      ansible.builtin.copy:\\n        content: \\\"{{ html_content }}\\\"\\n        dest: \\\"/var/www/html/index.html\\\"' > playbook.yml\"
      }
    ]"
    ;;
  "fr")
    question="Il existe un projet Ansible dans $project_dir avec un fichier 'playbook.yml' qui installe Apache et copie un fichier 'index.html' codé en dur. En suivant les bonnes pratiques Ansible, refactorisez le playbook pour utiliser les variables nommées 'web_package' et 'html_content' pour le nom du paquet ('apache2') et le contenu HTML ('Bienvenue sur mon serveur web') afin d'améliorer la flexibilité et la maintenabilité."
    hint="Définissez les variables nommées 'web_package' et 'html_content' dans le playbook sous une section 'vars' et référencez-les dans les tâches avec la syntaxe Jinja2 (par exemple, {{ web_package }} et {{ html_content }})."
    instructions="[
      {
        \"instruction\": \"Naviguez vers le répertoire du projet:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Mettez à jour 'playbook.yml' pour inclure les variables 'web_package' et 'html_content' et les utiliser dans les tâches:\",
        \"command\": \"echo -e '---\\n- name: Configurer le serveur web\\n  hosts: localhost\\n  vars:\\n    web_package: apache2\\n    html_content: \\\"Bienvenue sur mon serveur web\\\"\\n  tasks:\\n    - name: Installer Apache\\n      ansible.builtin.apt:\\n        name: \\\"{{ web_package }}\\\"\\n        state: present\\n    - name: Copier index.html\\n      ansible.builtin.copy:\\n        content: \\\"{{ html_content }}\\\"\\n        dest: \\\"/var/www/html/index.html\\\"' > playbook.yml\"
      }
    ]"
    ;;
  "de")
    question="Es gibt ein Ansible-Projekt in $project_dir mit einer Datei 'playbook.yml', die Apache installiert und eine fest codierte 'index.html'-Datei kopiert. Refaktorisieren Sie das Playbook gemäß Ansible-Best-Practices, um die Variablen 'web_package' und 'html_content' für den Paketnamen ('apache2') und den HTML-Inhalt ('Willkommen auf meinem Webserver') zu verwenden, um Flexibilität und Wartbarkeit zu verbessern."
    hint="Definieren Sie die Variablen 'web_package' und 'html_content' im Playbook unter einem 'vars'-Abschnitt und verweisen Sie in den Aufgaben mit Jinja2-Syntax darauf (z. B. {{ web_package }} und {{ html_content }})."
    instructions="[
      {
        \"instruction\": \"Wechseln Sie zum Projektverzeichnis:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aktualisieren Sie 'playbook.yml', um die Variablen 'web_package' und 'html_content' einzuführen und in den Aufgaben zu verwenden:\",
        \"command\": \"echo -e '---\\n- name: Webserver konfigurieren\\n  hosts: localhost\\n  vars:\\n    web_package: apache2\\n    html_content: \\\"Willkommen auf meinem Webserver\\\"\\n  tasks:\\n    - name: Apache installieren\\n      ansible.builtin.apt:\\n        name: \\\"{{ web_package }}\\\"\\n        state: present\\n    - name: index.html kopieren\\n      ansible.builtin.copy:\\n        content: \\\"{{ html_content }}\\\"\\n        dest: \\\"/var/www/html/index.html\\\"' > playbook.yml\"
      }
    ]"
    ;;
  "es")
    question="Existe un proyecto de Ansible en $project_dir con un archivo 'playbook.yml' que instala Apache y copia un archivo 'index.html' codificado en duro. Siguiendo las mejores prácticas de Ansible, refactorice el playbook para usar las variables nombradas 'web_package' y 'html_content' para el nombre del paquete ('apache2') y el contenido HTML ('Bienvenido a mi servidor web') para mejorar la flexibilidad y el mantenimiento."
    hint="Defina las variables nombradas 'web_package' y 'html_content' en el playbook bajo una sección 'vars' y refiéralas en las tareas usando la sintaxis de Jinja2 (por ejemplo, {{ web_package }} y {{ html_content }})."
    instructions="[
      {
        \"instruction\": \"Navega al directorio del proyecto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Actualiza 'playbook.yml' para incluir las variables 'web_package' y 'html_content' y usarlas en las tareas:\",
        \"command\": \"echo -e '---\\n- name: Configurar el servidor web\\n  hosts: localhost\\n  vars:\\n    web_package: apache2\\n    html_content: \\\"Bienvenido a mi servidor web\\\"\\n  tasks:\\n    - name: Instalar Apache\\n      ansible.builtin.apt:\\n        name: \\\"{{ web_package }}\\\"\\n        state: present\\n    - name: Copiar index.html\\n      ansible.builtin.copy:\\n        content: \\\"{{ html_content }}\\\"\\n        dest: \\\"/var/www/html/index.html\\\"' > playbook.yml\"
      }
    ]"
    ;;
  "it")
    question="Esiste un progetto Ansible in $project_dir con un file 'playbook.yml' che installa Apache e copia un file 'index.html' codificato in modo fisso. Seguendo le migliori pratiche di Ansible, rifattorizza il playbook per usare le variabili chiamate 'web_package' e 'html_content' per il nome del pacchetto ('apache2') e il contenuto HTML ('Benvenuto sul mio server web') per migliorare la flessibilità e la manutenibilità."
    hint="Definisci le variabili chiamate 'web_package' e 'html_content' nel playbook sotto una sezione 'vars' e fai riferimento a esse nei compiti usando la sintassi Jinja2 (ad esempio, {{ web_package }} e {{ html_content }})."
    instructions="[
      {
        \"instruction\": \"Naviga nella directory del progetto:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Aggiorna 'playbook.yml' per includere le variabili 'web_package' e 'html_content' e usarle nei compiti:\",
        \"command\": \"echo -e '---\\n- name: Configurare il server web\\n  hosts: localhost\\n  vars:\\n    web_package: apache2\\n    html_content: \\\"Benvenuto sul mio server web\\\"\\n  tasks:\\n    - name: Installare Apache\\n      ansible.builtin.apt:\\n        name: \\\"{{ web_package }}\\\"\\n        state: present\\n    - name: Copiare index.html\\n      ansible.builtin.copy:\\n        content: \\\"{{ html_content }}\\\"\\n        dest: \\\"/var/www/html/index.html\\\"' > playbook.yml\"
      }
    ]"
    ;;
  *)
    question="There is an Ansible project in $project_dir with a 'playbook.yml' file that installs Apache and copies a hardcoded 'index.html' file. Following Ansible best practices, refactor the playbook to use variables named 'web_package' and 'html_content' for the package name ('apache2') and the HTML content ('Welcome to my web server') to improve flexibility and maintainability."
    hint="Define variables named 'web_package' and 'html_content' in the playbook under a 'vars' section and reference them in the tasks using Jinja2 syntax (e.g., {{ web_package }} and {{ html_content }})."
    instructions="[
      {
        \"instruction\": \"Navigate to the project directory:\",
        \"command\": \"cd $project_dir\"
      },
      {
        \"instruction\": \"Update 'playbook.yml' to include variables 'web_package' and 'html_content' and use them in tasks:\",
        \"command\": \"echo -e '---\\n- name: Configure web server\\n  hosts: localhost\\n  vars:\\n    web_package: apache2\\n    html_content: \\\"Welcome to my web server\\\"\\n  tasks:\\n    - name: Install Apache\\n      ansible.builtin.apt:\\n        name: \\\"{{ web_package }}\\\"\\n        state: present\\n    - name: Copy index.html\\n      ansible.builtin.copy:\\n        content: \\\"{{ html_content }}\\\"\\n        dest: \\\"/var/www/html/index.html\\\"' > playbook.yml\"
      }
    ]"
    ;;
esac

display=$(cat <<EOF
{
  "question": "$question",
  "type": "button",
  "hint": "$hint",
  "instructions": $instructions,
  "text": "Check",
  "plateforme_required": "server",
  "os_required": "ubuntu"
}
EOF
)

# Use jq to pretty print the JSON (optional)
echo "$display" | jq .