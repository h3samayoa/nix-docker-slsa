// Positive control. The EICAR test string is the industry-standard harmless
// "malware" every scanner must detect. The literal is split so that this
// repository never contains the complete string (some endpoint AV quarantines
// it on clone); ci reassembles it into a fixture at scan time.
rule EICAR_Test_File
{
    meta:
        description = "EICAR anti-malware test file (positive control)"
        reference   = "https://www.eicar.org/download-anti-malware-testfile/"
    strings:
        $a = "EICAR-STANDARD-ANTIVIRUS-TEST-FILE" ascii
    condition:
        $a
}
