// Matches the canary constant that app/accept.go compiles into the binary
// on the demo/vulnerable branch. A build from main must NOT match; a
// match proves the YARA gate scanned the binary built from that change.
rule App_Bad_Canary
{
    meta:
        description = "Canary planted by the vulnerable demo change; a hit on main is a build-integrity failure"
    strings:
        $canary = "NIX-DOCKER-SLSA-CANARY-7f3a9c" ascii
    condition:
        $canary
}
