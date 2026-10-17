{
  description = "nix-docker-slsa";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/55bfb4d7437bd4e09ab7cba58a43bd68eb310044";

  outputs =
    { self, nixpkgs }:
    let
      target = "x86_64-linux";
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      # https://zerforschen.plus/posts/why-i-do-not-use-flake-utils/
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      rev = self.rev or self.dirtyRev or "dirty";
    in
    {
      packages.${target} =
        let
          pkgs = nixpkgs.legacyPackages.${target};
          app = pkgs.callPackage ./default.nix { };
          image = pkgs.callPackage ./image.nix { inherit app rev; };
        in
        {
          inherit app image;
          inherit (image) runtime-env;
          default = app;
        };

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.callPackage ./shell.nix { };
      });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
