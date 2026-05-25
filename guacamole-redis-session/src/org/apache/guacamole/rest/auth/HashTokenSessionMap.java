/*
 * Redis-backed drop-in replacement for Guacamole's HashTokenSessionMap.
 *
 * PROBLEM:
 *   The original HashTokenSessionMap stores session tokens in a
 *   ConcurrentHashMap local to each JVM. With 2+ replicas, pod A creates
 *   a token that pod B never sees → user gets 403 on every other request.
 *
 * SOLUTION:
 *   - Token validity (token → username) is stored in Redis with TTL.
 *     All pods share the same Redis, so any pod knows if a token is valid.
 *   - GuacamoleSession objects stay in local memory (they hold live socket
 *     connections to guacd that cannot be serialized or migrated).
 *   - Cross-pod hit: token found in Redis but not locally → reconstruct a
 *     fresh GuacamoleSession for that user by calling getUserContext() on
 *     each registered auth provider (PostgreSQL looks the user up in DB).
 *     Active tunnels are not restored (user must reconnect RDP/VNC/SSH),
 *     but navigation, settings, and UI are fully seamless.
 *
 * ENVIRONMENT VARIABLES (set on the guacamole-web Deployment):
 *   REDIS_HOSTNAME  — Redis service name (default: "redis")
 *   REDIS_PORT      — Redis port (default: 6379)
 *   REDIS_PASSWORD  — Redis AUTH password
 */
package org.apache.guacamole.rest.auth;

import com.google.inject.Inject;
import com.google.inject.Provider;
import com.google.inject.Singleton;
import org.apache.guacamole.GuacamoleException;
import org.apache.guacamole.GuacamoleSession;
import org.apache.guacamole.environment.Environment;
import org.apache.guacamole.net.auth.AbstractAuthenticatedUser;
import org.apache.guacamole.net.auth.AuthenticatedUser;
import org.apache.guacamole.net.auth.AuthenticationProvider;
import org.apache.guacamole.net.auth.Credentials;
import org.apache.guacamole.net.auth.UserContext;
import org.apache.guacamole.rest.event.ListenerService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPool;
import redis.clients.jedis.JedisPoolConfig;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Singleton
public class HashTokenSessionMap implements TokenSessionMap {

    private static final Logger logger = LoggerFactory.getLogger(HashTokenSessionMap.class);

    // Redis key prefix — avoids collisions if Redis is shared with other apps
    private static final String REDIS_KEY_PREFIX = "guac:token:";

    // ----------------------------------------------------------------
    // Local in-memory map — GuacamoleSession holds live guacd sockets
    // and cannot be serialized, so it stays per-pod.
    // ----------------------------------------------------------------
    private final ConcurrentHashMap<String, GuacamoleSession> localMap = new ConcurrentHashMap<>();

    // Background thread: evicts local sessions whose Redis TTL expired
    private final ScheduledExecutorService executor =
            Executors.newSingleThreadScheduledExecutor(r -> {
                Thread t = new Thread(r, "guac-session-eviction");
                t.setDaemon(true);
                return t;
            });

    // ----------------------------------------------------------------
    // Dependencies injected by Guice after the constructor runs.
    // They are used only in get()/put()/remove(), which Guice will not
    // call before injection is complete.
    // ----------------------------------------------------------------

    // All registered auth providers (ban, postgresql, etc.)
    // Guice binds these as List<AuthenticationProvider> in RESTAuthModule
    @Inject
    private List<AuthenticationProvider> authProviders;

    // Wraps each raw UserContext with decoration from every provider
    @Inject
    private DecorationService decorationService;

    // Required by GuacamoleSession constructor
    @Inject
    private ListenerService listenerService;

    // Provides the current HTTP request (request-scoped via Guice servlet).
    // Used during cross-pod session reconstruction so auth providers
    // (e.g. ban extension) can read the client IP and cookies correctly.
    @Inject
    private Provider<javax.servlet.http.HttpServletRequest> httpRequestProvider;

    // ----------------------------------------------------------------
    // Redis connection pool — initialized from environment variables
    // ----------------------------------------------------------------
    private JedisPool jedisPool;

    // Session timeout in seconds — kept in sync with Guacamole's setting
    private int sessionTtlSeconds = 3600; // default: 60 minutes

    // ----------------------------------------------------------------
    // Constructor — same signature as the original HashTokenSessionMap
    // so Guice can substitute it without changing RESTAuthModule.
    // ----------------------------------------------------------------
    @Inject
    public HashTokenSessionMap(Environment environment) {

        // Read Guacamole's api-session-timeout (minutes) if configured.
        // getProperty() is generic — IntegerGuacamoleProperty returns Integer directly.
        try {
            Integer timeoutMinutes = environment.getProperty(
                new org.apache.guacamole.properties.IntegerGuacamoleProperty() {
                    @Override public String getName() { return "api-session-timeout"; }
                }
            );
            if (timeoutMinutes != null) sessionTtlSeconds = timeoutMinutes * 60;
        } catch (Exception e) {
            logger.debug("api-session-timeout not set, using default {}s", sessionTtlSeconds);
        }

        initRedis();

        // Evict local sessions whose Redis TTL expired once per timeout period
        long evictIntervalMinutes = Math.max(1, sessionTtlSeconds / 60);
        executor.scheduleAtFixedRate(
            this::evictExpiredLocalSessions,
            evictIntervalMinutes,
            evictIntervalMinutes,
            TimeUnit.MINUTES
        );
    }

    // Build the Jedis connection pool from environment variables.
    // If Redis is unreachable, Guacamole still starts — sessions just
    // won't be shared across pods until Redis comes back.
    private void initRedis() {
        String host = System.getenv().getOrDefault("REDIS_HOSTNAME", "redis");
        int    port = Integer.parseInt(System.getenv().getOrDefault("REDIS_PORT", "6379"));
        String pass = System.getenv("REDIS_PASSWORD");

        JedisPoolConfig cfg = new JedisPoolConfig();
        cfg.setMaxTotal(20);
        cfg.setMaxIdle(10);
        cfg.setMinIdle(2);
        cfg.setTestOnBorrow(true);

        try {
            jedisPool = (pass != null && !pass.isEmpty())
                ? new JedisPool(cfg, host, port, 3000, pass)
                : new JedisPool(cfg, host, port, 3000);
            logger.info("[Redis session store] Connected to {}:{}", host, port);
        } catch (Exception e) {
            logger.error("[Redis session store] Failed to connect to {}:{} — sessions will NOT be shared across pods: {}",
                host, port, e.getMessage());
        }
    }

    // ----------------------------------------------------------------
    // TokenSessionMap interface
    // ----------------------------------------------------------------

    /**
     * Store a new session. Called by Guacamole immediately after a
     * successful login.
     *
     * Writes to:
     *   1. localMap  — for fast local lookups
     *   2. Redis     — so other pods know the token is valid
     */
    @Override
    public void put(String token, GuacamoleSession session) {
        localMap.put(token, session);

        // Store token → username in Redis with TTL
        // If Redis is unavailable the login still works, just not cross-pod
        if (jedisPool != null) {
            try (Jedis jedis = jedisPool.getResource()) {
                String username = session.getAuthenticatedUser().getIdentifier();
                jedis.setex(REDIS_KEY_PREFIX + token, sessionTtlSeconds, username);
                logger.debug("[Redis session store] Stored token for user '{}'", username);
            } catch (Exception e) {
                logger.warn("[Redis session store] put() failed — token will be local-only: {}", e.getMessage());
            }
        }
    }

    /**
     * Retrieve a session by token.
     *
     * Fast path  — found in localMap → return immediately.
     * Cross-pod  — not local but found in Redis → reconstruct session
     *              from PostgreSQL and cache it locally for next time.
     * Not found  — return null → Guacamole returns 403 to the client.
     */
    @Override
    public GuacamoleSession get(String token) {

        // 1. Local fast path
        GuacamoleSession session = localMap.get(token);
        if (session != null) {
            session.access();
            refreshTtl(token); // keep Redis TTL aligned with activity
            return session;
        }

        // 2. Cross-pod: check Redis
        if (jedisPool == null) return null;

        String username;
        try (Jedis jedis = jedisPool.getResource()) {
            username = jedis.get(REDIS_KEY_PREFIX + token);
        } catch (Exception e) {
            logger.warn("[Redis session store] get() Redis lookup failed: {}", e.getMessage());
            return null;
        }

        if (username == null) return null; // token unknown to all pods → 403

        // 3. Token valid on another pod — rebuild session for this user
        logger.info("[Redis session store] Reconstructing session for '{}' from cross-pod token", username);
        try {
            return reconstructSession(token, username);
        } catch (Exception e) {
            logger.error("[Redis session store] Session reconstruction failed for '{}': {}", username, e.getMessage());
            return null;
        }
    }

    /**
     * Remove a session on logout or timeout.
     * Deletes from both localMap and Redis so all pods immediately
     * stop accepting this token.
     */
    @Override
    public GuacamoleSession remove(String token) {

        // Guacamole calls remove(null) on failed login attempts.
        // ConcurrentHashMap does not accept null keys, so guard here.
        if (token == null) return null;

        // Remove from Redis first — all pods stop accepting this token
        if (jedisPool != null) {
            try (Jedis jedis = jedisPool.getResource()) {
                jedis.del(REDIS_KEY_PREFIX + token);
            } catch (Exception e) {
                logger.warn("[Redis session store] remove() Redis delete failed: {}", e.getMessage());
            }
        }

        GuacamoleSession session = localMap.remove(token);
        if (session != null) session.invalidate();
        return session;
    }

    @Override
    public void shutdown() {
        executor.shutdownNow();
        if (jedisPool != null && !jedisPool.isClosed()) jedisPool.close();
    }

    // ----------------------------------------------------------------
    // Session reconstruction
    // ----------------------------------------------------------------

    /**
     * Build a GuacamoleSession for a user whose token exists in Redis
     * (created by another pod) but not in our localMap.
     *
     * Steps:
     *   1. Create a minimal AuthenticatedUser with just the username.
     *      No password — Redis token IS the proof of prior auth.
     *   2. Call getUserContext() on every registered auth provider.
     *      PostgreSQL will look the user up in the DB and return a
     *      UserContext with their connections and permissions.
     *   3. Wrap each UserContext with DecorationService (same as a
     *      normal login flow).
     *   4. Build GuacamoleSession and cache it locally.
     *
     * Active tunnels (RDP/VNC/SSH) are NOT restored — the user must
     * reconnect those. Navigation and settings work immediately.
     */
    private GuacamoleSession reconstructSession(String token, String username)
            throws GuacamoleException {

        // Build credentials with the live HTTP request so auth providers
        // (ban extension, postgresql) can read client IP and cookies.
        // Password is null — the Redis token IS the proof of prior auth.
        javax.servlet.http.HttpServletRequest currentRequest = httpRequestProvider.get();
        Credentials credentials = new Credentials(username, null, currentRequest);

        // Minimal AuthenticatedUser backed only by username
        // getAuthenticationProvider() returns the first registered provider
        // as a placeholder; individual providers query by username in DB
        AbstractAuthenticatedUser user = new AbstractAuthenticatedUser() {
            @Override
            public AuthenticationProvider getAuthenticationProvider() {
                return authProviders.isEmpty() ? null : authProviders.iterator().next();
            }
            @Override
            public Credentials getCredentials() { return credentials; }
        };
        user.setIdentifier(username);

        // Collect a DecoratedUserContext from each provider
        List<DecoratedUserContext> contexts = new ArrayList<>();
        for (AuthenticationProvider provider : authProviders) {
            try {
                UserContext ctx = provider.getUserContext(user);
                if (ctx == null) continue;

                // Decorate exactly as Guacamole does on normal login
                DecoratedUserContext decorated = decorationService.decorate(ctx, user, credentials);
                contexts.add(decorated);

            } catch (Exception e) {
                // Non-fatal: skip providers that refuse to cooperate
                // (e.g. ban extension returning null for this user)
                logger.debug("[Redis session store] Provider '{}' skipped during reconstruction: {}",
                    provider.getIdentifier(), e.getMessage());
            }
        }

        if (contexts.isEmpty()) {
            // User may have been deleted or disabled since they logged in
            logger.warn("[Redis session store] No contexts found for '{}' — removing stale Redis token", username);
            try (Jedis jedis = jedisPool.getResource()) {
                jedis.del(REDIS_KEY_PREFIX + token);
            } catch (Exception ignored) {}
            return null;
        }

        GuacamoleSession newSession = new GuacamoleSession(listenerService, user, contexts);
        localMap.put(token, newSession); // cache so next request is a local fast-path hit
        return newSession;
    }

    // ----------------------------------------------------------------
    // Maintenance
    // ----------------------------------------------------------------

    // Extend the Redis TTL every time the session is actively used.
    // This mirrors how the original HashTokenSessionMap resets the
    // inactivity timer on each access.
    private void refreshTtl(String token) {
        if (jedisPool == null) return;
        try (Jedis jedis = jedisPool.getResource()) {
            jedis.expire(REDIS_KEY_PREFIX + token, sessionTtlSeconds);
        } catch (Exception e) {
            // Non-critical — TTL will just count down from last set
        }
    }

    // Periodically remove local sessions that Redis has already expired.
    // This keeps memory clean when users naturally time out.
    private void evictExpiredLocalSessions() {
        if (jedisPool == null) return;
        localMap.forEach((token, session) -> {
            try (Jedis jedis = jedisPool.getResource()) {
                if (!jedis.exists(REDIS_KEY_PREFIX + token)) {
                    localMap.remove(token, session);
                    session.invalidate();
                    logger.debug("[Redis session store] Evicted expired local session for token {}", token);
                }
            } catch (Exception e) {
                // Skip on Redis failure — session stays local until next cycle
            }
        });
    }
}
