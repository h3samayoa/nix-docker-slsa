# nix-docker-slsa

A small Go service, built for `x86_64-linux` on a GitHub-hosted **arm64** runner
through an emulated amd64 Nix container used as a Nix remote builder. Every
release ships with two provenance documents, three SBOMs, every scan report
and a signed verdict. Findings block a pull request and pause a release until a
named reviewer accepts them with a reason, which becomes a signed VEX.

```
ubuntu-24.04-arm (GitHub-hosted)              amd64 container (QEMU, one per job)
┌───────────────────────────────┐   ssh    ┌──────────────────────────────┐
│ nix (aarch64) --max-jobs 0    │ ───────► │ nixos/nix 2.31.6 + sshd      │
│ eval, SBOM, scan, attest      │ ◄─────── │ every x86_64-linux derivation│
└───────────────────────────────┘ outputs  └──────────────────────────────┘
```

## important

| what | where |
|---|---|
| A clean release: 28 files, verdict PASSED | [release v0.1.0](https://github.com/h3samayoa/nix-docker-slsa/releases/tag/v0.1.0) · [run 39169791572](https://github.com/h3samayoa/nix-docker-slsa/actions/runs/39169791572) |
| A release with accepted findings: signed VEX and verdict by exception | [release v0.1.0-vuln](https://github.com/h3samayoa/nix-docker-slsa/releases/tag/v0.1.0-vuln) · [run 39188112133](https://github.com/h3samayoa/nix-docker-slsa/actions/runs/39188112133) |
| A blocked pull request: three scanners, merge disabled | [pull request #4](https://github.com/h3samayoa/nix-docker-slsa/pull/4) (branch `demo/vuln`) |
| Every signed attestation, as GitHub shows it | [attestations](https://github.com/h3samayoa/nix-docker-slsa/attestations) |
| The builder image and its attestation | [packages](https://github.com/h3samayoa/nix-docker-slsa/pkgs/container/nix-docker-slsa%2Fbuilder) |

Verify any release yourself with the GitHub CLI and nothing else:

```sh
gh release download v0.1.0 -R h3samayoa/nix-docker-slsa -p app-x86_64-linux -p 'app.*.sigstore.json'
gh attestation verify app-x86_64-linux --owner h3samayoa                                    # provenance, online
gh attestation verify app-x86_64-linux --owner h3samayoa --bundle app.provenance.sigstore.json   # same, offline
gh attestation verify app-x86_64-linux --owner h3samayoa --predicate-type https://cyclonedx.org/bom   # signed SBOM
printf x >> app-x86_64-linux && gh attestation verify app-x86_64-linux --owner h3samayoa   # one byte changed: fails
```

## What is in a release

| file | proves |
|---|---|
| `app-x86_64-linux`, `app-image-x86_64-linux.tar.gz`, `SHA256SUMS` | the artifacts |
| `app.provenance.sigstore.json` | who built it, on which runner, from which commit (SLSA provenance, GitHub) |
| `app.nix-provenance.sigstore.json`, `provenance.nix.*.json` | from what: every Nix build input by hash (sbomnix) |
| `sbom.buildtime.*`, `sbom.analyzed.*`, `sbom.runtime.*` | 842 build inputs, 3 components in the binary (attested), 5 files in the image |
| `grype.*`, `govulncheck.txt`, `yara-matches.txt`, `checksec.json`, `findings.json` | every scan, unedited; `findings.json` is what the gate counted |
| `policy.vulns.json`, `grype-db.txt` | the policy's own output and the vulnerability database date |
| `app-x86_64-linux.vsa.json` | the verdict: PASSED or FAILED, the policy and the commit it was taken from |
| `app.openvex.json`, `app-x86_64-linux.vsa.exception.json` (v0.1.0-vuln only) | the reviewer's accepted findings, and the verdict by exception that cites them |
| `builder-image.txt`, `buildinfo.txt`, `path-info.json` | which builder built it, Go version, store paths |

## Layout

| path | role |
|---|---|
| [`app/`](app/) | the service: `/healthz` and `/version` on `main`. The `demo/vuln` branch adds `/greet` with `golang.org/x/text v0.3.7` (CVE-2022-32149, called on request input) and a YARA canary |
| [`flake.nix`](flake.nix), [`default.nix`](default.nix), [`image.nix`](image.nix), [`shell.nix`](shell.nix) | the package, the image (binary + CA bundle, non-root), and the shell holding every scanner, all pinned to one nixpkgs commit |
| [`builder/`](builder/) | the remote-builder image: `nixos/nix:2.31.6-amd64` by digest, key-only sshd, host keys made at start. The Dockerfile comment explains `filter-syscalls = false` |
| [`.github/workflows/build-attest.yml`](.github/workflows/build-attest.yml) | the only job that builds and signs: verifies the builder image's attestation, builds through it with `--max-jobs 0`, writes SBOMs, provenance, scans and `findings.json` |
| [`.github/workflows/verify.yml`](.github/workflows/verify.yml) | the consumer: signature, signer, runner, source commit and checksum gates, Rego policy, then the verdict |
| [`.github/workflows/ci.yml`](.github/workflows/ci.yml) | every push and pull request: linters → builder image if needed → build → verify → `security` (required check) → PR comment |
| [`.github/workflows/release.yml`](.github/workflows/release.yml) | every tag: build → verify → clean: publish · findings: pause at the `release` environment → approve with a reason: VEX + verdict by exception → publish · reject: nothing |
| [`.github/workflows/build-image.yml`](.github/workflows/build-image.yml) | builds, pushes and attests the builder image when `builder/` changes on `main` |
| [`.github/scripts/`](.github/scripts/) | `start-builder.sh`, `vsa.sh` (verification summary), `openvex.sh` (VEX from findings + approval) |
| [`policy/`](policy/) | Rego: `provenance.rego` (builder id, hosted runner, source) and `vulns.rego` (the gate: any Critical or High in the analyzed or runtime scan) |
| [`yara/`](yara/) | the EICAR control rule; the canary rule arrives with `demo/vuln` |

## The four outcomes

| outcome | integrity gates | findings | result |
|---|---|---|---|
| blocked (pull request) | pass | some | `security` check fails; nothing merges; no override |
| verified (tag) | pass | none | verdict PASSED → release |
| denied (tag) | **fail** | any | nothing; no review offered |
| denied (tag) | pass | some | reviewer rejected; nothing; FAILED verdict stays in the run |
| accepted (tag) | pass | some | reviewer approved with a reason → signed VEX + verdict by exception → release |

Integrity is never reviewable. Findings are routed: on a pull request, fix it;
on a tag, a person decides, and the decision is signed.

