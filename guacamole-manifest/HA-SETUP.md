# Guacamole Cluster — High Availability Setup

## Infrastructure

| Server | Role | IP |
|---|---|---|
| hzn-k8s-master-jilani | Kubernetes master | `<MASTER-PRIVATE-IP>` |
| hzn-k8s-worker-1-jilani | Kubernetes worker | `<WORKER-PRIVATE-IP>` |
| hzn-bastion-jilani | Bastion / entry point | `<BASTION-PUBLIC-IP>` |

**Container runtime:** containerd 1.7.28  
**Kubernetes version:** v1.35.3

---

## Problem: Default Setup Was Not HA

The original deployment had every component at `replicas: 1`. This meant:

- A single pod failure = full service outage
- No load distribution across users
- `guacamole-web` could not be scaled because sessions were stored in JVM memory (in-memory `HashTokenSessionMap`)

---

## Step 1 — Understand the Components

| Component | Role | Can scale? |
|---|---|---|
| `postgres` | Stores users, connections, permissions | No — PV is `ReadWriteOnce` |
| `guacd` | Handles RDP/VNC/SSH protocol tunneling | Yes — stateless |
| `guacamole-web` | Web frontend + REST API | No (yet) — sessions in memory |
| `init-db` | One-time DB schema init job | N/A |

---

## Step 2 — Why guacamole-web Could Not Scale

Apache Guacamole stores session tokens in a class called `HashTokenSessionMap`:

```
ConcurrentHashMap<token, GuacamoleSession>   ← lives in each pod's JVM memory
```

With 2+ replicas:
- User logs in → token stored in **pod A memory**
- Next request hits **pod B** → token not found → HTTP 403 → user kicked out

### Rejected solutions

| Option | Why rejected |
|---|---|
| IP-based sticky sessions | All users route through same proxy IP → all land on same pod |
| Cookie-based affinity (Ingress) | Rejected — wanted proper stateless solution |
| Redis (off the shelf) | Guacamole doesn't natively support Redis session storage |

### Chosen solution: patch `HashTokenSessionMap` + Redis

Replace Guacamole's in-memory session map with a Redis-backed version — without rebuilding Guacamole from source.

---

## Step 3 — Deploy Redis

File: `05-redis.yaml`

- Redis 7.2 with AOF persistence (`appendonly yes`, `appendfsync everysec`)
- AOF ensures sessions survive Redis pod restarts — users stay logged in
- Password-protected via Kubernetes Secret (`redis-secret`)
- ClusterIP Service with DNS name `redis` — accessible by all pods

```bash
kubectl apply -f guacamole-manifest/05-redis.yaml
```

---

## Step 4 — Patch Guacamole's Session Map

File: `guacamole-redis-session/src/org/apache/guacamole/rest/auth/HashTokenSessionMap.java`

### How it works

The patched `HashTokenSessionMap` replaces the original class inside `guacamole.war` at build time.

**On login (any pod):**
1. Token created → stored in pod's local map (fast path)
2. Token + username also stored in Redis with TTL (60 min)

**On API request (same pod):**
- Token found in local map → served immediately

**On API request (different pod — cross-pod hit):**
1. Token not in local map
2. Check Redis → found: `{username: "guacadmin"}`
3. Reconstruct `GuacamoleSession`:
   - Create minimal `AuthenticatedUser` with username
   - Call `getUserContext()` on each auth provider (PostgreSQL looks user up in DB)
   - Wrap contexts with `DecorationService`
   - Build `GuacamoleSession` and cache locally
4. User continues seamlessly — no login page

**On logout:**
- Token deleted from both local map and Redis → all pods immediately stop accepting it

### Key design decisions

- `GuacamoleSession` stays in local memory (holds live socket connections — cannot be serialized)
- Only the token → username mapping goes to Redis
- Active RDP/VNC/SSH tunnels are NOT migrated across pods (user must reconnect if pod restarts mid-session — acceptable trade-off)
- Redis failure degrades gracefully: sessions still work locally, just not cross-pod

### Bugs fixed during development

| Bug | Cause | Fix |
|---|---|---|
| Guice `CreationException` at startup | Injected `Set<AuthenticationProvider>` but Guice binds a `List` | Changed to `List<AuthenticationProvider>` |
| `NullPointerException` on failed login | Guacamole calls `remove(null)` on auth failure, `ConcurrentHashMap` rejects null keys | Added `if (token == null) return null` guard |
| `getCookies()` NullPointerException during reconstruction | Passed `null` as `HttpServletRequest` to `Credentials` | Injected `Provider<HttpServletRequest>` to pass the live request |

---

## Step 5 — Build and Push the New Image

File: `guacamole-redis-session/Dockerfile`

Multi-stage build — only patches the WAR, does not rebuild Guacamole from source:

```
Stage 1 (eclipse-temurin:21-jdk):
  - Copy guacamole.war from jilanigh/guacamole:custom-v1.10
  - Extract WAR
  - Download jedis-5.1.0.jar + commons-pool2-2.12.0.jar
  - Copy servlet-api.jar from Tomcat (needed at compile time)
  - Compile HashTokenSessionMap.java against WAR's classpath
  - Replace HashTokenSessionMap.class in WEB-INF/classes
  - Repack WAR

Stage 2 (jilanigh/guacamole:custom-v1.10):
  - Replace /opt/guacamole/webapp/guacamole.war with patched version
```

```bash
cd guacamole-redis-session
docker build -t jilanigh/guacamole:redis-v1 .
docker push jilanigh/guacamole:redis-v1
```

---

## Step 6 — Update guacamole-web Deployment

File: `03-guacamole-web.yaml`

Changes:
- `replicas: 1` → `replicas: 3`
- Image: `custom-v1.10` → `redis-v1`
- Added Redis env vars:

```yaml
- name: REDIS_HOSTNAME
  value: "redis"
- name: REDIS_PORT
  value: "6379"
- name: REDIS_PASSWORD
  valueFrom:
    secretKeyRef:
      name: redis-secret
      key: redis-password
```

```bash
kubectl apply -f guacamole-manifest/03-guacamole-web.yaml
```

---

## Final Architecture

```
                    ┌─────────────────────────────────────┐
                    │           guacamole-web              │
                    │                                      │
          ┌─────────┤  pod 1  │  pod 2  │  pod 3          │
          │         │  (local │  (local │  (local          │
          │         │   map)  │   map)  │   map)           │
          │         └────────────────────────┬────────────┘
          │                                  │ shared token store
          │                             ┌────▼────┐
          │                             │  Redis  │
          │                             │  (AOF)  │
          │                             └─────────┘
          │
    ┌─────▼─────┐          ┌──────────┐
    │  guacd    │          │ postgres │
    │ (tunnels) │          │  (data)  │
    └───────────┘          └──────────┘
```

## Final Pod Count

| Pod | Replicas | Notes |
|---|---|---|
| `guacamole-web` | 3 | Sessions shared via Redis |
| `guacd` | 1 | Scale freely when needed |
| `postgres` | 1 | ReadWriteOnce PV — cannot scale without HA DB solution |
| `redis` | 1 | AOF persistence enabled |

---

## Proof It Works

Live logs after deployment showed cross-pod reconstruction working with zero errors:

```
10:35:11 - User "guacadmin" authenticated          ← logged in on pod A
10:35:11 - Reconstructing session on pod B         ← next request hit pod B → Redis token found
10:37:00 - Reconstructing session on pod C         ← request hit pod C → same
10:37:57 - Reconstructing session on pod B/C       ← continuous cross-pod serving
```

User logged in once and all 3 pods served their requests without a session error.
