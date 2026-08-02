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

## License & attribution

The contents of this repository (Dockerfile, workflows, Renovate config) are licensed under the
[Apache License 2.0](./LICENSE).

The published image bundles third-party software under its own terms:

- **Keycloak** — Apache-2.0, © the Keycloak authors.
- **Docker Hardened Images** — the DHI definitions, patches and build scripts are Apache-2.0
  ([docker-hardened-images/catalog](https://github.com/docker-hardened-images/catalog)). Packages
  and binaries included in the base image remain under their respective upstream licenses.
- **Debian base packages** — under their individual licenses, including copyleft ones (glibc and
  others). Corresponding sources are available from Debian; the exact package set and versions are
  listed in the image's SBOM.

The complete license inventory for a given image ships with it:

```bash
docker buildx imagetools inspect docker.io/powerofcreation/keycloak@sha256:<digest> \
  --format '{{ json .SBOM }}'
```

### Changes made to the base image

Per Apache-2.0 §4(b), this image is a modified version of `dhi.io/keycloak`. The modifications are:

- `kc.sh build` is run in the `-dev` stage with `KC_DB=postgres`, `KC_HEALTH_ENABLED=true` and
  `KC_METRICS_ENABLED=true`, producing an optimized Keycloak distribution.
- That build result (`/opt/keycloak/`) is copied into the hardened runtime stage, and the default
  command is `start --optimized`.

No Keycloak or base image sources are patched.

### Trademarks

This is not an official Docker or Keycloak product. It is not affiliated with, endorsed by, or
sponsored by Docker, Inc., Red Hat, Inc., or the Keycloak project. "Docker", "Docker Hardened
Images" and "Keycloak" are trademarks of their respective owners and are used here descriptively
only; the Apache-2.0 license of the underlying works grants no trademark rights (§6).
