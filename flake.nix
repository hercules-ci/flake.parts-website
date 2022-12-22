{
  description = "The https://flake.parts website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";

    dream2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.url = "github:nix-community/dream2nix";
    haskell-flake.url = "github:srid/haskell-flake";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
    mission-control.url = "github:Platonic-Systems/mission-control";
    mission-control.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    proc-flake.url = "github:srid/proc-flake";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      perSystem.render.inputs = {

        dream2nix = {
          title = "dream2nix beta";
          baseUrl = "https://github.com/nix-community/dream2nix/blob/master";
          attributePath = [ "flakeModuleBeta" ];
          intro = ''
            [`dream2nix`](https://github.com/nix-community/dream2nix#readme) scans your flake files and turns them into packages.
          '';
        };

        flake-parts = {
          title = "Core Options";
          baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main";
          getModules = _: [ ];
          intro = ''
            These options are provided by default. They reflect what Nix expects,
            plus a small number of helpful options, notably [`perSystem`](#opt-perSystem).
          '';
          installation = "";
        };

        haskell-flake = {
          baseUrl = "https://github.com/srid/haskell-flake/blob/master";
          intro = ''
            [`haskell-flake`](https://github.com/srid/haskell-flake) scans your flake files for Haskell projects and
            turns them into packages using the Nixpkgs Haskell infrastructure.

            It also provides [`checks`](flake-parts.html#opt-perSystem.checks) and [`devShells`](flake-parts.html#opt-perSystem.devShells)

            Multiple projects can be declared to represent each package set, which is great for GHCJS frontends.
          '';
        };

        hercules-ci-effects = {
          baseUrl = "https://github.com/hercules-ci/hercules-ci-effects/blob/master";
          intro = ''
            This module provides
             - a mergeable `herculesCI` attribute; read by [Hercules CI](https://hercules-ci.com) and the [`hci`](https://docs.hercules-ci.com/hercules-ci-agent/hci/) command,
             - the [`hci-effects`](https://docs.hercules-ci.com/hercules-ci-effects/guide/import-or-pin/#_flakes_with_flake_parts) library as a module argument in `perSystem` / `withSystem`,
             - ready to go, configurable continuous deployment jobs
          '';
        };

        mission-control = {
          baseUrl = "https://github.com/Platonic-Systems/mission-control/blob/main";
          intro = ''
            A flake-parts module for your Nix devshell scripts.

            Lets you configure commands that will be run in the repository root.

            Provides an informative "message of the day" when launching your shell.

            See the [Platonic-Systems/mission-control readme](https://github.com/Platonic-Systems/mission-control#readme).
          '';
        };

        pre-commit-hooks-nix = {
          baseUrl = "https://github.com/cachix/pre-commit-hooks.nix/blob/master";
          intro = ''
            Configure pre-commit hooks.

            Generates a configuration for [pre-commit](https://pre-commit.com),
            provides a script to activate it, and adds a [check](flake-parts.html#opt-perSystem.checks).

            Pre-defined hooks are maintained at [`cachix/pre-commit-hooks.nix`](https://github.com/cachix/pre-commit-hooks.nix).
          '';
        };

        proc-flake = {
          baseUrl = "https://github.com/srid/proc-flake/blob/master";
          intro = ''
            A module for running multiple processes in a dev shell.

            [honcho](https://github.com/nickstenning/honcho) is used to launch the processes.

            See [proc-flake README](https://github.com/srid/proc-flake#readme)
          '';
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

      hercules-ci.flake-update = {
        enable = true;
        when = {
          hour = [ 8 20 ];
        };
        autoMergeMethod = "merge";
      };
    };
}
