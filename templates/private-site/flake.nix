{
  description = "Description for the project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts-website.url = "github:hercules-ci/flake.parts-website";

    # Example
    my-flake-module.url = "github:srid/haskell-flake";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts-website.flakeModules.empty-site
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem = {
        render.inputs.my-flake-module = {
          # TODO: update
          baseUrl = "https://github.com/foo/my-flake-module/blob/main";
          intro = ''
            My private flake-parts module, with docs rendered here.
          '';
        };
      };
    };
}
