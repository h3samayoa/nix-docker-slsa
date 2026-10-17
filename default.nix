{ buildGoModule }:

buildGoModule {
  pname = "app";
  version = "0.1.0";
  src = ./app;

  vendorHash = null;

  env.CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
  ];

  meta.mainProgram = "app";
}
