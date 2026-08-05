# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

# ---- Stage 1: optimized Keycloak build on hardened DHI dev base (Postgres baked in) ----
FROM dhi.io/keycloak:26.7.0-dev@sha256:16286290456427378c2dabd6179588b9eb303795a9e16e43431de5bbb5a6c5f8 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: hardened DHI runtime (hardcoded, tracked by Renovate) ----
FROM dhi.io/keycloak:26.7.0@sha256:c27bef6dd76f67ff13a572cb112dff9b03d319e03c89a77a8086c5dcf0fcc9cd
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
