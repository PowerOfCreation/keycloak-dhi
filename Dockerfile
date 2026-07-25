# syntax=docker/dockerfile:1

# ---- Stage 1: optimierter Keycloak-Build (Postgres fest eingebacken) ----
FROM quay.io/keycloak/keycloak:26.7.0 AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: gehärtete DHI-Runtime (hardcoded, von Renovate getrackt) ----
FROM dhi.io/keycloak:26.7.0
COPY --from=builder --chown=65532:0 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
