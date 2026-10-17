{
  lib,
  buildEnv,
  dockerTools,
  cacert,
  tzdata,
  curl,
  app,
  rev,
}:

let
  runtime-env = buildEnv {
    name = "runtime-env";
    paths = [
      app
      cacert
      tzdata
      curl
    ];
  };
in
dockerTools.buildLayeredImage { # testing
  name = "app";
  tag = rev;
  contents = [ runtime-env ];
  config = {
    Cmd = [ (lib.getExe app) ];
    ExposedPorts."8080/tcp" = { };
    Env = [ "SSL_CERT_FILE=/etc/ssl/certs/ca-bundle.crt" ];
    Labels = {
      "org.opencontainers.image.revision" = rev;
      "org.opencontainers.image.title" = "app";
      "nix.store-path.app" = "${app}";
      "nix.store-path.runtime-env" = "${runtime-env}";
    };
  };
  passthru = { inherit runtime-env; };
}
