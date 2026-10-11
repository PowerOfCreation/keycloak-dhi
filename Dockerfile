# syntax=docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

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
