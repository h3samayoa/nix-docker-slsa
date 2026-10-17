# conftest policy over grype JSON output (grype sbom:<file> -o json).
# This is the SECURITY policy the Verification Summary Attestation cites
# (policy.uri → this directory): a Critical/High finding means the VSA is
# FAILED and the release routes to human review. It is reported, never
# suppressed; acceptance is recorded as OpenVEX + a VSA by exception.
package vulns

import rego.v1

blocking_severities := {"Critical", "High"}

deny contains msg if {
	some m in input.matches
	m.vulnerability.severity in blocking_severities
	msg := sprintf("%s (%s) in %s@%s", [
		m.vulnerability.id,
		m.vulnerability.severity,
		m.artifact.name,
		m.artifact.version,
	])
}
