# syntax=docker/dockerfile:1.27.1@sha256:4edf897a3ffa55b89f906fc8cc78afdb3f1834cc9c7083565e611a8a7d5fe99e

# ---- Stage 1: optimized Keycloak build on the hardened DHI base (Postgres baked in) ----
FROM dhi.io/keycloak:26.8.1@sha256:85c0863e9c0534c15e096e01db61c516112acd2ba626b427f11d1afc8ed002fe AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: hardened DHI runtime (hardcoded, tracked by Renovate) ----
FROM dhi.io/keycloak:26.8.1@sha256:85c0863e9c0534c15e096e01db61c516112acd2ba626b427f11d1afc8ed002fe
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
