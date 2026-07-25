# Security Policy

## Meldung von Sicherheitslücken

Bitte Sicherheitslücken in diesem Repository (Dockerfile, Build-Pipeline) über
[GitHub Security Advisories](https://github.com/PowerOfCreation/keycloak-dhi/security/advisories/new) melden,
nicht über öffentliche Issues.

Für Schwachstellen in Keycloak selbst gilt der Meldeweg des Upstream-Projekts:
https://www.keycloak.org/security

## Unterstützte Versionen

Nur der jeweils in `Dockerfile` gepinnte Keycloak-Release wird gebaut und gepflegt. Ältere
Image-Tags erhalten keine Patches; auf die neueste Version aktualisieren.

## Wie diese Pipeline Sicherheit adressiert

- Basis-Image: [Docker Hardened Images](https://docs.docker.com/dhi/) für alle Build- und
  Runtime-Stages (kein ungehärteter Upstream-Layer im finalen Image).
- SBOM (SPDX/CycloneDX via BuildKit) und Provenance (`mode=max`) werden bei jedem Build erzeugt.
- Images werden per `cosign` keyless (GitHub OIDC) signiert.
- Jeder Build wird mit Trivy gescannt; Ergebnisse landen im GitHub-Security-Tab (Code Scanning).
- Renovate hält Base-Image-Digests und Keycloak-Version aktuell.

Details und Verifikationskommandos siehe [README.md](./README.md).
