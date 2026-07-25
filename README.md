# keycloak-dhi

Hardened Keycloak image based on [Docker Hardened Images](https://docs.docker.com/dhi/) (DHI),
with Postgres baked in (`kc.sh build`), built automatically and pushed to
`docker.io/powerofcreation/keycloak`.

## Getting the image

```bash
# by digest (recommended, immutable)
docker pull docker.io/powerofcreation/keycloak@sha256:<digest>

# by tag
docker pull docker.io/powerofcreation/keycloak:<keycloak-version>
```

Tags pushed per build:

- `<keycloak-version>` (e.g. `26.7.0`)
- `<keycloak-version>-<git-sha>`
- `<keycloak-version>-r<n>` (sequential release number, see [Releases](../../releases))

There is deliberately no `latest` tag — every consumer pins explicitly to a version or a digest.

## How the image is hardened

Both build stages use DHI:

- **Builder:** `dhi.io/keycloak:<version>-dev` — Docker's own hardened Keycloak distribution
  (including Docker-maintained CVE patches, e.g. Netty overrides), not the unhardened upstream
  build.
- **Runtime:** `dhi.io/keycloak:<version>` — runs nonroot (`uid=gid=65532`), minimal package base.

The result therefore has JARs, JRE, and OS consistently from the hardened distribution, not just
the OS layer.

## Supply-chain attestations

Every build produces:

- **SBOM** (SPDX, via BuildKit/Syft) — a complete inventory of the final image stage, including
  the Keycloak JARs copied from the builder.
- **Provenance** (`mode=max`, SLSA) — includes the Dockerfile, build args, and base image digest.
- **cosign signature** (keyless, via GitHub OIDC), `--recursive` — signs the multi-arch index
  *and* every individual platform manifest (including the attestation manifests). `cosign verify`
  therefore works on both the index digest and the amd64 or arm64 child digest.
- **Smoke test** — before tags are set, the pushed (still untagged) digest is started against a
  real Postgres instance and checked for `/health/ready`. Only after that do `:<version>` and
  `:<version>-r<n>` point at the image at all; on failure it stays an untagged manifest with no
  release.
- **Trivy scan** (SARIF) — results in the repo's [Security tab](../../security/code-scanning).

### Verifying

```bash
# Signature
cosign verify docker.io/powerofcreation/keycloak@sha256:<digest> \
  --certificate-identity-regexp '^https://github.com/PowerOfCreation/keycloak-dhi/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# Fetch SBOM
docker buildx imagetools inspect docker.io/powerofcreation/keycloak@sha256:<digest> --format '{{ json .SBOM }}'

# Fetch provenance (shows, among other things, the base image digest of dhi.io/keycloak)
docker buildx imagetools inspect docker.io/powerofcreation/keycloak@sha256:<digest> --format '{{ json .Provenance }}'

# View DHI's own signed SBOM/VEX/CVE attestations of the base image directly
docker scout attest list dhi.io/keycloak:<version>
```

### What's carried over — and what isn't

The pushed image gets its own complete SBOM covering the entire final filesystem content (base
layer *and* Keycloak JARs) — that covers the practical "SBOM for consumers" use case.

What is **not** automatically inherited: Docker's own signed SBOM/VEX/CVE attestations of the
`dhi.io/keycloak` base. An image derived from it gets fresh, own attestations; there is no merge
mechanism between base and derived image attestations. Anyone who wants to inspect the base's DHI
attestations themselves uses the base image digest from the provenance and fetches them directly
from DHI (`docker scout attest list`, see above).

## Renovate

`renovate.json5` keeps `dhi.io/keycloak` (builder and runtime tag) in one group so both stages
never end up on different Keycloak versions.
