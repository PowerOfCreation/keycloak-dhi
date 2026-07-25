# Security Policy

## Reporting vulnerabilities

Please report vulnerabilities in this repository (Dockerfile, build pipeline) via
[GitHub Security Advisories](https://github.com/PowerOfCreation/keycloak-dhi/security/advisories/new),
not via public issues.

For vulnerabilities in Keycloak itself, use the upstream project's reporting channel:
https://www.keycloak.org/security

## Supported versions

Only the Keycloak release currently pinned in `Dockerfile` is built and maintained. Older
image tags do not receive patches; update to the latest version.

## How this pipeline addresses security

- Base image: [Docker Hardened Images](https://docs.docker.com/dhi/) for all build and runtime
  stages (no unhardened upstream layer in the final image).
- SBOM (SPDX via BuildKit) and provenance (`mode=max`) are generated on every build.
- Images are signed with `cosign` keyless (GitHub OIDC).
- Every build is scanned with Trivy; results land in the GitHub Security tab (Code Scanning).
- Renovate keeps base image digests and the Keycloak version up to date.

See [README.md](./README.md) for details and verification commands.
