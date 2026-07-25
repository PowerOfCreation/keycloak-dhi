# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89

# ---- Stage 1: optimized Keycloak build on hardened DHI dev base (Postgres baked in) ----
FROM dhi.io/keycloak:26.7.0-dev@sha256:2e2110f6db8e4d8a7637c0c4168e276d61024190e18788339bc77e773e881094 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: hardened DHI runtime (hardcoded, tracked by Renovate) ----
FROM dhi.io/keycloak:26.7.0@sha256:dd797b934027879a3d99442b3c51b877c72209145b6ec1022ea840b9cf9d4018
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
