{
  description = "The https://flake.parts website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs"; # https://github.com/NixOS/nix/issues/7730
    dream2nix.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";
    dream2nix.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix.url = "github:nix-community/dream2nix";
    emanote.url = "github:srid/emanote";
    emanote.inputs.nixpkgs.follows = "nixpkgs";
    haskell-flake.url = "github:srid/haskell-flake";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
    mission-control.url = "github:Platonic-Systems/mission-control";
    nix-cargo-integration.url = "github:yusdacra/nix-cargo-integration";
    nix-cargo-integration.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
    pre-commit-hooks-nix.inputs.nixpkgs.follows = "nixpkgs";
    proc-flake.url = "github:srid/proc-flake";
    process-compose-flake.url = "github:hercules-ci/process-compose-flake/fix-docs";
    std.url = "github:divnix/std";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ lib, ... }: {
      perSystem.render.inputs = {

        devshell = {
          title = "devshell";
          baseUrl = "https://github.com/numtide/devshell/blob/main";
          intro = ''
            Simple per-project developer environments.

            Example:

            ```nix
            perSystem = { config, pkgs, ... }: {
              devshells.default = {
                env = [
                  {
                    name = "HTTP_PORT";
                    value = 8080;
                  }
                ];
                commands = [
                  {
                    help = "print hello";
                    name = "hello";
                    command = "echo hello";
                  }
                ];
                packages = [
                  pkgs.cowsay
                ];
              };
            };
            ```

            See also the [`devshell` project page](https://github.com/numtide/devshell)
          '';
        };

        dream2nix = {
          title = "dream2nix beta";
          baseUrl = "https://github.com/nix-community/dream2nix/blob/master";
          attributePath = [ "flakeModuleBeta" ];
          intro = ''
            [`dream2nix`](https://github.com/nix-community/dream2nix#readme) scans your flake files and turns them into packages.
          '';
        };

        emanote = {
          baseUrl = "https://github.com/srid/emanote/blob/master";
          intro = ''
            [`Emanote`](https://github.com/srid/emanote) renders your Markdown
            files as a nice static site with hot reload.

            Use `nix run` to run the live server, and `nix build` to build the
            static site.

            See
            [emanote-template](https://github.com/srid/emanote-template/blob/master/flake.nix)
            for an example `flake.nix`.
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

        flake-parts-easyOverlay =
          let sourceSubpath = "/extras/easyOverlay.nix";
          in
          {
            _module.args.name = lib.mkForce "flake-parts";
            flake = inputs.flake-parts;
            title = "flake-parts.easyOverlay";
            baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main${sourceSubpath}";
            getModules = f: [ f.flakeModules.easyOverlay ];
            intro = ''
              Derives a default overlay from `perSystem.packages`.
            '';
            installationDeclareInput = false;
            attributePath = [ "flakeModules" "easyOverlay" ];
            separateEval = true;
            filterTransformOptions =
              { sourceName, sourcePath, baseUrl, coreOptDecls }:
              let sourcePathStr = toString sourcePath + sourceSubpath;
              in
              opt:
              let
                declarations = lib.concatMap
                  (decl:
                    if lib.hasPrefix sourcePathStr (toString decl)
                    then
                      let subpath = lib.removePrefix sourcePathStr (toString decl);
                      in [{ url = baseUrl + subpath; name = sourceName + subpath; }]
                    else [ ]
                  )
                  opt.declarations;
              in
              if declarations == [ ]
              then opt // { visible = false; }
              else opt // { inherit declarations; };
          };

        haskell-flake = {
          baseUrl = "https://github.com/srid/haskell-flake/blob/master";
          intro = ''
            [`haskell-flake`](https://haskell.flake.page/) scans your flake files for Haskell projects and
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

        nix-cargo-integration = {
          title = "nix-cargo-integration";
          baseUrl = "https://github.com/yusdacra/nix-cargo-integration/blob/master";
          attributePath = [ "flakeModuleNciOnly" ];
          intro = ''
            Easily integrate your Rust projects into Nix.
          '';
          installation = ''
            ## Installation

            See the [readme](https://github.com/yusdacra/nix-cargo-integration#readme).
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

        process-compose-flake = {
          baseUrl = "https://github.com/Platonic-Systems/process-compose-flake/blob/main";
          intro = ''
            Declare one or more process-compose configurations using options.

            Generates a wrapper for [process-compose](https://github.com/F1bonacc1/process-compose).

            See [process-compose-flake](https://github.com/Platonic-Systems/process-compose-flake) for a [usage example](https://github.com/Platonic-Systems/process-compose-flake#usage).
          '';
        };

        std = {
          baseUrl = "https://github.com/divnix/std/blob/main";
          intro = ''
            Add definitions from the [Standard](https://github.com/divnix/std#readme) DevOps framework to your flake.

            It organizes and disciplines your Nix and thereby speeds you up.
            It also comes with great horizontal integrations of high quality 
            vertical DevOps tooling crafted by the Nix Ecosystem.
          '';
        };

        treefmt-nix = {
          baseUrl = "https://github.com/numtide/treefmt-nix/blob/master";
          intro = ''
            When working on large code trees, it's common to have multiple code formatters run against it. And have one script that loops over all of them. `treefmt` makes that nicer.

             - A unified CLI and output
             - Run all the formatters in parallel.
             - Cache which files have changed for super fast re-formatting.
             - Just type treefmt in any folder and it reformats the whole code tree.

            This module is defined in [`numtide/treefmt-nix`](https://github.com/numtide/treefmt-nix). The `treefmt` repo is about the [tool](https://github.com/numtide/treefmt) itself. 
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
      systems = [
        # Supported, see `ciSystems`
        "x86_64-linux"

        # Available, but may be broken by Nixpkgs updates sometimes
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      hercules-ci.flake-update = {
        enable = true;
        when = {
          hour = [ 8 20 ];
        };
        autoMergeMethod = "merge";
      };

      herculesCI = {
        ciSystems = [ "x86_64-linux" ];
      };
    });
}
