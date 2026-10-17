#!/usr/bin/env bash
# Emit a SLSA Verification Summary Attestation predicate (v1) on stdout.
#   vsa.sh <PASSED|FAILED> <resourceUri> <verifierId> <policyUri> [inputAttestation files...]
# Each input attestation file is recorded by name and sha256 so the VSA says
# exactly which provenance / SBOM / VEX documents the verdict was based on.
set -euo pipefail

result="$1"; resource="$2"; verifier="$3"; policy="$4"; shift 4

inputs='[]'
for f in "$@"; do
  [ -f "$f" ] || continue
  sha="$(sha256sum "$f" | cut -d' ' -f1)"
  inputs="$(jq -c --arg u "$(basename "$f")" --arg s "$sha" '. + [{uri: $u, digest: {sha256: $s}}]' <<<"$inputs")"
done

jq -n \
  --arg verifier "$verifier" \
  --arg time "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg resource "$resource" \
  --arg policy "$policy" \
  --arg result "$result" \
  --argjson inputs "$inputs" \
  '{
     verifier: { id: $verifier },
     timeVerified: $time,
     resourceUri: $resource,
     policy: { uri: $policy },
     inputAttestations: $inputs,
     verificationResult: $result,
     verifiedLevels: (if $result == "PASSED" then ["SLSA_BUILD_LEVEL_3"] else [] end),
     slsaVersion: "1.2"
   }'
