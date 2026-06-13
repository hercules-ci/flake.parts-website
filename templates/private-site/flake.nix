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
        render.inputs.my-flake-module = input: {
          imports = [
            inputs.flake-parts-website.modules.flakePartsRenderInput.github
            # Or GitLab:
            # inputs.flake-parts-website.modules.flakePartsRenderInput.gitlab
          ];
          owner = "me";
          repo = "my-flake-module";
          # Otherwise, remove `imports`, `owner`, and `repo` and specify:
          # baseUrl = lib.mkIf (
          #   input.config.rev != null
          # ) "https://my-forge.com/me/my-repo/-/blob/${input.config.rev}";
          intro = ''
            My private flake-parts module, with docs rendered here.
          '';
        };
      };
    };
}
