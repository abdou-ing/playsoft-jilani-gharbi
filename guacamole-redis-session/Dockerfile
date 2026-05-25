# ============================================================
# Build a Redis-aware Guacamole image
#
# WHAT THIS DOES:
#   Takes the existing custom Guacamole image, extracts the
#   guacamole.war, replaces HashTokenSessionMap.class with our
#   Redis-backed version, adds the Jedis library, repacks the
#   WAR, and puts it back.
#
# No full source rebuild — only ONE class is replaced.
#
# HOW TO BUILD:
#   docker build -t jilanigh/guacamole:redis-v1 .
#
# HOW TO PUSH:
#   docker push jilanigh/guacamole:redis-v1
# ============================================================


# ── Stage 1: patch the WAR ────────────────────────────────────
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /build

# Copy the WAR from the existing custom image
COPY --from=jilanigh/guacamole:custom-v1.10 \
     /opt/guacamole/webapp/guacamole.war \
     /build/guacamole.war

# Extract the WAR into a working directory
RUN mkdir war && cd war && jar xf /build/guacamole.war

# Download Jedis (Redis Java client) and its required pool library.
# We pin exact versions so the build is reproducible.
# commons-pool2 is required by Jedis for connection pooling.
RUN curl -fSL \
    "https://repo1.maven.org/maven2/redis/clients/jedis/5.1.0/jedis-5.1.0.jar" \
    -o war/WEB-INF/lib/jedis-5.1.0.jar && \
    curl -fSL \
    "https://repo1.maven.org/maven2/org/apache/commons/commons-pool2/2.12.0/commons-pool2-2.12.0.jar" \
    -o war/WEB-INF/lib/commons-pool2-2.12.0.jar

# Copy our Redis-backed HashTokenSessionMap source into the build
COPY src/org/apache/guacamole/rest/auth/HashTokenSessionMap.java \
     /build/HashTokenSessionMap.java

# servlet-api.jar is needed at compile time (javax.servlet.http.HttpServletRequest).
# It ships with Tomcat inside the Guacamole image — copy it from there.
COPY --from=jilanigh/guacamole:custom-v1.10 \
     /usr/local/tomcat/lib/servlet-api.jar \
     /build/servlet-api.jar

# Compile HashTokenSessionMap.java against:
#   - WEB-INF/lib/*       → guacamole-ext, guice, slf4j, jedis (just added)
#   - WEB-INF/classes     → GuacamoleSession, TokenSessionMap, DecorationService, etc.
#   - /build/servlet-api  → javax.servlet.http.HttpServletRequest
#
# Output goes directly into WEB-INF/classes, replacing the original .class
RUN javac \
    -source 11 -target 11 \
    -cp "war/WEB-INF/lib/*:war/WEB-INF/classes:/build/servlet-api.jar" \
    -d war/WEB-INF/classes \
    /build/HashTokenSessionMap.java

# Repack the patched WAR
RUN cd war && jar cf /build/guacamole-redis.war .


# ── Stage 2: final image ──────────────────────────────────────
# Start from the same base so all original extensions, scripts,
# and entrypoints are preserved exactly as before.
FROM jilanigh/guacamole:custom-v1.10

# Replace the original WAR with our Redis-patched one
COPY --from=builder /build/guacamole-redis.war \
     /opt/guacamole/webapp/guacamole.war
