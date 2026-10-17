#!/usr/bin/env bash
# Emit an OpenVEX v0.2.0 document on stdout from a grype JSON report and a
# reviewer's approval. Every Critical/High finding becomes a statement with
# status `affected` and the approval comment as the action statement:
# acceptance is recorded as "present and accepted because...", never as
# "not affected" without one of the spec's justifications.
#   openvex.sh <grype.json> <product-id> <author> <comment> <doc-id>
set -euo pipefail

grype="$1"; product="$2"; author="$3"; comment="$4"; docid="$5"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -n \
  --slurpfile g "$grype" \
  --arg product "$product" \
  --arg author "$author" \
  --arg comment "$comment" \
  --arg ts "$ts" \
  --arg docid "$docid" \
  '{
     "@context": "https://openvex.dev/ns/v0.2.0",
     "@id": $docid,
     author: $author,
     role: "release reviewer",
     timestamp: $ts,
     version: 1,
     statements: (
       [ $g[0].matches[]
         | select(.vulnerability.severity == "Critical" or .vulnerability.severity == "High")
         | { vulnerability: { name: .vulnerability.id },
             products: [ { "@id": $product, subcomponents: [ { "@id": .artifact.purl } ] } ],
             status: "affected",
             action_statement: $comment,
             action_statement_timestamp: $ts } ]
       | unique )
   }'
