# conftest policy over the JSON output of:
#   gh attestation verify <artifact> --owner <owner> --format json
# The input is an array; each element has verificationResult.statement
# (the in-toto statement) and verificationResult.signature.certificate.
#
# These assertions are what turn "we have provenance" into "we checked the
# provenance says what SLSA Build L3 requires of it".
package provenance

import rego.v1

expected_build_type := "https://actions.github.io/buildtypes/workflow/v1"
expected_predicate_type := "https://slsa.dev/provenance/v1"

# Set via --data or edit for the target repository.
expected_signer_workflow := data.expected.signer_workflow
expected_source_repo := data.expected.source_repo

# conftest unwraps a top-level JSON array and evaluates each element as
# `input`; opa eval passes the whole array. Accept both shapes.
statements contains s if {
	s := input.verificationResult.statement
}

statements contains s if {
	some r in input
	s := r.verificationResult.statement
}

deny contains msg if {
	count(statements) == 0
	msg := "no verified attestation statements in input"
}

deny contains msg if {
	some s in statements
	s.predicateType != expected_predicate_type
	msg := sprintf("unexpected predicateType %q", [s.predicateType])
}

deny contains msg if {
	some s in statements
	s.predicate.buildDefinition.buildType != expected_build_type
	msg := sprintf("unexpected buildType %q", [s.predicate.buildDefinition.buildType])
}

deny contains msg if {
	some s in statements
	s.predicate.buildDefinition.internalParameters.github.runner_environment != "github-hosted"
	msg := "build did not run on a GitHub-hosted runner (SLSA Build L2 requires a hosted platform)"
}

deny contains msg if {
	some s in statements
	not startswith(s.predicate.runDetails.builder.id, expected_signer_workflow)
	msg := sprintf("builder.id %q is not the expected reusable workflow %q", [s.predicate.runDetails.builder.id, expected_signer_workflow])
}

deny contains msg if {
	some s in statements
	not source_present(s)
	msg := sprintf("resolvedDependencies does not name the source repository %q", [expected_source_repo])
}

source_present(s) if {
	some d in s.predicate.buildDefinition.resolvedDependencies
	contains(d.uri, expected_source_repo)
	d.digest.gitCommit
}
