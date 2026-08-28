# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32

# ---- Stage 1: optimized Keycloak build on the hardened DHI base (Postgres baked in) ----
FROM dhi.io/keycloak:26.7.2@sha256:8c3158b706dc684bf5616f4a8b7f83540f0b2e903373e4f96ef42ce8aa8ee975 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: hardened DHI runtime (hardcoded, tracked by Renovate) ----
FROM dhi.io/keycloak:26.7.2@sha256:8c3158b706dc684bf5616f4a8b7f83540f0b2e903373e4f96ef42ce8aa8ee975
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
