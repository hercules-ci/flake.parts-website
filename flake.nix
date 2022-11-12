{
  description = "The https://flake.parts website";

  inputs = {
    nixpkgs.url = "github:hercules-ci/nixpkgs/options-markdown-and-errors";

    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
    haskell-flake.url = "github:srid/haskell-flake";
    haskell-flake.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.url = "github:nix-community/dream2nix";
    dream2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ self, flake-parts, hercules-ci-effects, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      perSystem.render.inputs = {
        flake-parts = {
          title = "Core Options";
          baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main";
          getModules = _: [ ];
        };
        hercules-ci-effects = {
          baseUrl = "https://github.com/hercules-ci/hercules-ci-effects/blob/master";
        };
        pre-commit-hooks-nix = {
          baseUrl = "https://github.com/hercules-ci/pre-commit-hooks.nix/blob/flakeModule";
        };
        haskell-flake = {
          baseUrl = "https://github.com/srid/haskell-flake/blob/master";
        };
        dream2nix = {
          title = "dream2nix beta";
          baseUrl = "https://github.com/nix-community/dream2nix/blob/master";
          getModules = flake: [ flake.flakeModuleBeta ];
        };
      };
      imports = [
        ./render/render-module.nix
        ./site/site-module.nix
        ./dev-module.nix
        ./deploy-module.nix
        inputs.hercules-ci-effects.flakeModule
        inputs.pre-commit-hooks-nix.flakeModule
      ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
    };
}
