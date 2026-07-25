# keycloak-dhi

Gehärtetes Keycloak-Image auf Basis von [Docker Hardened Images](https://docs.docker.com/dhi/) (DHI),
mit Postgres fest eingebacken (`kc.sh build`), automatisiert gebaut und nach
`docker.io/powerofcreation/keycloak` gepusht.

## Image beziehen

```bash
# per Digest (empfohlen, unveränderlich)
docker pull docker.io/powerofcreation/keycloak@sha256:<digest>

# per Tag
docker pull docker.io/powerofcreation/keycloak:<keycloak-version>
```

Gepushte Tags pro Build:

- `<keycloak-version>` (z. B. `26.7.0`)
- `<keycloak-version>-<git-sha>`
- `<keycloak-version>-r<n>` (fortlaufende Release-Nummer, siehe [Releases](../../releases))

Es gibt bewusst keinen `latest`-Tag — jeder Konsument pinnt explizit auf eine Version oder einen Digest.

## Wie das Image gehärtet ist

Beide Build-Stages nutzen DHI:

- **Builder:** `dhi.io/keycloak:<version>-dev` — die DHI-eigene Keycloak-Distribution (inkl. der von
  Docker gepflegten CVE-Patches, z. B. Netty-Overrides), nicht der ungehärtete Upstream-Build.
- **Runtime:** `dhi.io/keycloak:<version>` — läuft nonroot (`uid=gid=65532`), minimale Paketbasis.

Das Ergebnis enthält also durchgängig JARs, JRE und OS aus der gehärteten Distribution, nicht nur die
OS-Schicht.

## Supply-Chain-Attestations

Jeder Build erzeugt:

- **SBOM** (SPDX/CycloneDX, via BuildKit/Syft) — vollständiges Inventar der finalen Image-Stage,
  inklusive der aus dem Builder kopierten Keycloak-JARs.
- **Provenance** (`mode=max`, SLSA) — Dockerfile, Build-Args und Base-Image-Digest sind enthalten.
- **cosign-Signatur** (keyless, über GitHub OIDC), `--recursive` — signiert sind der Multi-Arch-Index
  *und* jedes einzelne Plattform-Manifest (inkl. der Attestation-Manifeste). `cosign verify`
  funktioniert also sowohl auf dem Index-Digest als auch auf dem amd64- oder arm64-Kind-Digest.
- **Smoke-Test** — bevor Tags gesetzt werden, wird der gepushte (noch ungetaggte) Digest gegen eine
  echte Postgres-Instanz gestartet und `/health/ready` geprüft. Erst danach zeigen `:<version>` und
  `:<version>-r<n>` überhaupt auf das Image; bei Fehlschlag bleibt es ein untagged Manifest ohne
  Release.
- **Trivy-Scan** (SARIF) — Ergebnisse im [Security-Tab](../../security/code-scanning) des Repos.

### Verifizieren

```bash
# Signatur
cosign verify docker.io/powerofcreation/keycloak@sha256:<digest> \
  --certificate-identity-regexp '^https://github.com/PowerOfCreation/keycloak-dhi/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com

# SBOM abrufen
docker buildx imagetools inspect docker.io/powerofcreation/keycloak@sha256:<digest> --format '{{ json .SBOM }}'

# Provenance abrufen (zeigt u. a. den Base-Image-Digest von dhi.io/keycloak)
docker buildx imagetools inspect docker.io/powerofcreation/keycloak@sha256:<digest> --format '{{ json .Provenance }}'

# DHIs eigene signierte SBOM/VEX/CVE-Attestations der Basis direkt einsehen
docker scout attest list dhi.io/keycloak:<version>
```

### Was durchgereicht wird — und was nicht

Das gepushte Image bekommt einen eigenen, vollständigen SBOM über den gesamten finalen Dateisystem-Inhalt
(Base-Layer *und* Keycloak-JARs) — das deckt den praktischen Anwendungsfall "SBOM für Konsumenten" ab.

Was **nicht** automatisch vererbt wird: Docker's eigene signierte SBOM-/VEX-/CVE-Attestations der
`dhi.io/keycloak`-Basis. Ein davon abgeleitetes Image bekommt frische, eigene Attestations; einen
Merge-Mechanismus zwischen Base- und Derived-Image-Attestations gibt es nicht. Wer die DHI-Attestations
der Basis selbst einsehen will, nutzt den Base-Image-Digest aus der Provenance und ruft sie direkt bei
DHI ab (`docker scout attest list`, s. o.).

## Renovate

`renovate.json5` hält `dhi.io/keycloak` (Builder- und Runtime-Tag) in einer gemeinsamen Gruppe, damit
beide Stages nie auf unterschiedlichen Keycloak-Versionen landen.
