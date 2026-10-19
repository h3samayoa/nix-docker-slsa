{ buildGoModule }:

buildGoModule {
  pname = "app";
  version = "0.1.0";
  src = ./app;

  # golang.org/x/text v0.3.7 (app/accept.go); the dependency set sets the hash.
  vendorHash = "sha256-eesSfFhpzeNkbMYegcKjnltlFpCG/ST6WO9qWQwlPJ4=";

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  meta.mainProgram = "app";
}
