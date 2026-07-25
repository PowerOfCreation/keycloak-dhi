# syntax=docker/dockerfile:1

# ---- Stage 1: optimierter Keycloak-Build auf gehärteter DHI-dev-Basis (Postgres fest eingebacken) ----
FROM dhi.io/keycloak:26.7.0-dev AS builder
ENV KC_DB=postgres \
    KC_HEALTH_ENABLED=true \
    KC_METRICS_ENABLED=true
RUN /opt/keycloak/bin/kc.sh build

# ---- Stage 2: gehärtete DHI-Runtime (hardcoded, von Renovate getrackt) ----
FROM dhi.io/keycloak:26.7.0
COPY --from=builder --chown=65532:65532 /opt/keycloak/ /opt/keycloak/
ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]
CMD ["start", "--optimized"]
