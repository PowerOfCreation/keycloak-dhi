# syntax=docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

# ---- Stage 1: optimized Keycloak build on the hardened DHI base (Postgres baked in) ----
FROM dhi.io/keycloak:26.7.4@sha256:ad28ab3334d6c4c1af649509a4864ba4d69054d647fc4d5d4ea511b56ff30611 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: hardened DHI runtime (hardcoded, tracked by Renovate) ----
FROM dhi.io/keycloak:26.7.4@sha256:ad28ab3334d6c4c1af649509a4864ba4d69054d647fc4d5d4ea511b56ff30611
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
