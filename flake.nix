{
  description = "The https://flake.parts website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    agenix-shell.url = "github:aciceri/agenix-shell";
    devenv.url = "github:hercules-ci/devenv/flake-module";
    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs"; # https://github.com/NixOS/nix/issues/7730
    dream2nix_legacy.inputs.pre-commit-hooks.follows = "pre-commit-hooks-nix";
    dream2nix_legacy.inputs.nixpkgs.follows = "nixpkgs";
    dream2nix_legacy.url = "github:nix-community/dream2nix/c9c8689f09aa95212e75f3108788862583a1cf5a";
    emanote.url = "github:srid/emanote";
    emanote.inputs.nixpkgs.follows = "nixpkgs";
    haskell-flake.url = "github:srid/haskell-flake";
    hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
    mission-control.url = "github:Platonic-Systems/mission-control";
    nix-cargo-integration.url = "github:yusdacra/nix-cargo-integration";
    nix-cargo-integration.inputs.nixpkgs.follows = "nixpkgs";
    nix-cargo-integration.inputs.dream2nix.follows = "dream2nix_legacy";
    ocaml-flake.url = "github:9glenda/ocaml-flake";
    ocaml-flake.inputs.nixpkgs.follows = "nixpkgs";
    ocaml-flake.inputs.treefmt-nix.follows = "treefmt-nix";
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

        agenix-shell = {
          title = "agenix-shell";
          baseUrl = "https://github.com/aciceri/agenix-shell/blob/master";
          attributePath = [ "flakeModules" "default" ];
          intro = ''
            [agenix-shell](https://github.com/aciceri/agenix-shell) is the [agenix](https://github.com/ryantm/agenix) counterpart for `devShell`.
            It provides options used to define a `shellHook` that, when added to your `devShell`, automatically decrypts secrets and export them.

            [Here](https://github.com/aciceri/agenix-shell/blob/master/templates/basic/flake.nix)'s a template you can start from.
          '';
        };

        devenv = {
          title = "devenv";
          baseUrl = "https://github.com/cachix/devenv/blob/main";
          attributePath = [ "flakeModule" ];
          intro = ''
            [`devenv`](https://devenv.sh) provides a devShell with many options, and container packages.

            See also the [setup guide at devenv.sh](https://devenv.sh/guides/using-with-flake-parts/).
          '';
          killLinks = true;
        };

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
          title = "dream2nix";
          baseUrl = "https://github.com/nix-community/dream2nix/blob/main";
          flakeRef = "github:nix-community/dream2nix";
          intro = ''
            This page is a placeholder while dream2nix v1 is in the works.
            See [dream2nix_legacy](./dream2nix_legacy.html) for the previous API.
          '';
          installation = "";
          attributePath = [ "modules" "flake-parts" "all-modules" ];
          flake = { modules.flake-parts.all-modules = { }; outPath = "/x"; };
        };

        dream2nix_legacy = {
          title = "dream2nix legacy";
          baseUrl = "https://github.com/nix-community/dream2nix/blob/c9c8689f09aa95212e75f3108788862583a1cf5a";
          flakeRef = "github:nix-community/dream2nix/c9c8689f09aa95212e75f3108788862583a1cf5a";
          attributePath = [ "flakeModuleBeta" ];
          intro = ''
            [`dream2nix`](https://github.com/nix-community/dream2nix#readme) scans your flake files and turns them into packages.

            NOTE: a new version of dream2nix, v1, is in the works, and we're figuring out how best to use it.
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
              ## WARNING

              This module does NOT make _consuming_ an overlay easy. This module is intended for _creating_ overlays.
              While it is possible to consume the overlay created by this module using the `final` module argument, this is somewhat unconventional. Instead:

              - _Avoid_ overlays. Many flakes can do without them.
              - Initialize `pkgs` yourself:
                ```
                perSystem = { system, ... }: {
                  _module.args.pkgs = import inputs.nixpkgs {
                    inherit system;
                    overlays = [
                      inputs.foo.overlays.default
                      (final: prev: {
                        # ... things you really need to patch ...
                      })
                    ];
                    config = { };
                  };
                };
                ```

              ## Who this is for

              This module is for flake authors who need to provide a simple overlay in addition to the common flake attributes. It is not for users who want to consume an overlay.

              ## What it actually does

              This module overrides the `pkgs` module argument and provides the `final` module argument so that the `perSystem` module can be evaluated as an overlay. Attributes added by the overlay must be defined in `overlayAttrs`. The resulting overlay is defined in the `overlays.default` output.

              The resulting behavior tends to be not 100% idiomatic. A hand-written overlay would usually use `final` more often, but nonetheless it gets the job done for simple use cases; certainly the simple use cases where overlays aren't strictly necessary.

              ## The status of this module

              It has an unfortunate name and may be renamed. Alternatively, its functionality may be moved out of flake-parts, into some Nixpkgs module. Certainly until then, feel free to use the module if you understand what it does.
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

        flake-parts-flakeModules =
          let sourceSubpath = "/extras/flakeModules.nix";
          in
          {
            _module.args.name = lib.mkForce "flake-parts";
            flake = inputs.flake-parts;
            title = "flake-parts.flakeModules";
            baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main${sourceSubpath}";
            getModules = f: [ f.flakeModules.flakeModules ];
            intro = ''
              Adds the `flakeModules` attribute and `flakeModule` alias.
              
              This module makes deduplication and `disabledModules` work, even if the definitions are inline modules or [`importApply`](../define-module-in-separate-file.html#importapply).
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
          attributePath = [ "flakeModule" ];
          intro = ''
            Easily integrate your Rust projects into Nix.
          '';
          installation = ''
            ## Installation

            See the [readme](https://github.com/yusdacra/nix-cargo-integration#readme).
          '';
        };

        ocaml-flake = {
          title = "ocaml-flake";
          baseUrl = "https://github.com/9glenda/ocaml-flake";
          attributePath = [ "flakeModule" ];
          intro = ''
            [`ocaml-flake`](https://github.com/9glenda/ocaml-flake) uses [`opam-nix`](https://github.com/tweag/opam-nix) to build ocaml packages. The module structure is inspired by [`haskell-flake`](https://haskell.flake.page/).

            Since the flake is fairly new future versions may introduce breaking changes.
          '';
          installation = ''
            ## Installation
            To initialize a new dune project using `ocaml-flake` simply run:
            ```sh
            nix flake init -t github:9glenda/ocaml-flake#simple
            ```
            This will set up a devshell and package for you.
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
