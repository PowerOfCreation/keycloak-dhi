# syntax=docker/dockerfile:1.28.0@sha256:bb22d9815c728170f72750f4e5b0d672e06176142e1d602c7e66c050100b7e5b

# ---- Stage 1: optimized Keycloak build on the hardened DHI base (Postgres baked in) ----
FROM dhi.io/keycloak:26.8.0@sha256:f7e3e180ac6cbbcef45587a1556a2a0c0ed679ec77d1d179b97a1a69449efe78 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: hardened DHI runtime (hardcoded, tracked by Renovate) ----
FROM dhi.io/keycloak:26.8.0@sha256:f7e3e180ac6cbbcef45587a1556a2a0c0ed679ec77d1d179b97a1a69449efe78
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
