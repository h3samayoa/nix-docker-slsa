{
  lib,
  stdenv,
  mkShellNoCC,
  go,
  govulncheck,
  sbomnix,
  syft,
  grype,
  yara-x,
  conftest,
  zizmor,
  pinact,
  actionlint,
  shellcheck,
  hadolint,
  gh,
  jq,
  checksec,
}:

mkShellNoCC {
  packages = [
    go
    govulncheck
    sbomnix
    syft
    grype
    yara-x
    conftest
    zizmor
    pinact
    actionlint
    shellcheck
    hadolint
    gh
    jq
  ]
  ++ lib.optional stdenv.hostPlatform.isLinux checksec;

  env.CGO_ENABLED = "0";
}
