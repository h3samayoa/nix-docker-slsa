{
  description = "nix-docker-slsa";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/55bfb4d7437bd4e09ab7cba58a43bd68eb310044";
    nixpkgs-go.url = "github:NixOS/nixpkgs/f0b687e10c0c5b2f199ca57127071ef922c0f92d";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-go,
    }:
    let
      target = "x86_64-linux";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # https://zerforschen.plus/posts/why-i-do-not-use-flake-utils/
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      rev = self.rev or self.dirtyRev or "dirty";
      goFor = system: nixpkgs-go.legacyPackages.${system}.go;
    in
    {
      packages.${target} =
        let
          pkgs = nixpkgs.legacyPackages.${target};
          app = pkgs.callPackage ./default.nix {
            buildGoModule = pkgs.buildGoModule.override { go = goFor target; };
          };
          image = pkgs.callPackage ./image.nix { inherit app rev; };
        in
        {
          inherit app image;
          inherit (image) runtime-env;
          default = app;
        };

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { go = goFor system; };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
