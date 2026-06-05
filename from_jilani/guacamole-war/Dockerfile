FROM jilanigh/guacamole:custom-v1.9

USER root

# Install zip to modify the WAR file
RUN apt-get update && apt-get install -y zip && rm -rf /var/lib/apt/lists/*

# Create a temporary directory for our custom files
COPY . /tmp/guac_custom/

# Update the official guacamole.war with our modified files
# We remove the .war itself from the temp folder first to avoid nesting
RUN rm -f /tmp/guac_custom/guacamole.war && \
    cd /tmp/guac_custom && \
    zip -r /opt/guacamole/webapp/guacamole.war *

# Cleanup
RUN rm -rf /tmp/guac_custom

USER guacamole
