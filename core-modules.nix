/*
  The modules from the flake-parts repo get a special treatment in the menu and
  the options for the core module need to be filtered differently.

  Furthermore, this module is required by the render module, so we include it
  in flakeModules.empty-site. (It's _comparatively_ empty.)
 */

{ lib, ... }: {
  config.perSystem = { config, ... }:
    let
      inputs = config.render.officialFlakeInputs;
    in
    {
      render.inputs = {
        flake-parts = {
          title = "Core Options";
          baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main";
          getModules = _: [ ];
          intro = ''
            These options are provided by default. They reflect what Nix expects,
            plus a small number of helpful options, notably [`perSystem`](#opt-perSystem).
          '';
          installation = "";
          menu.enable = false;
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
            menu.enable = false;
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
            menu.enable = false;
          };

        flake-parts-partitions =
          let sourceSubpath = "/extras/partitions.nix";
          in
          {
            _module.args.name = lib.mkForce "flake-parts";
            flake = inputs.flake-parts;
            title = "flake-parts.partitions";
            baseUrl = "https://github.com/hercules-ci/flake-parts/blob/main${sourceSubpath}";
            getModules = f: [ f.flakeModules.partitions ];
            intro = ''
              This module provides a performance optimization, and a way to reduce the size of the main `flake.lock` that is [currently](https://github.com/NixOS/nix/issues/7730) getting copied into all consuming flakes' lock files, which bothers some users.

              The goals of this module are:

              - **Do not load irrelevant modules** when you evaluate an attribute of an already locked flake, it . If the flake was locked remotely, the sources for those dependencies would still have to be fetched.
                This is achieved by moving some `imports` and their related definitons into [`partitions.<name>.module`](#opt-partitions._name_.module) and defining [`partitionAttrs.<attr>`](#opt-partitionedAttrs) to point to that partition.

              - **Don't copy irrelevant lock entries** when you lock a flake that has the current flake as its input.
                This can be achieved by moving inputs into a subflake whose only responsibility is to provide the inputs, and then pointing [`partitions.<name>.extraInputsFlake`](#opt-partitions._name_.extraInputsFlake) to that subflake.

              ## Example

              Definitions in the `mkFlake` root module (or a direct import into it):

              ```nix
              partitionedAttrs.checks = "dev";
              partitionedAttrs.devShells = "dev";
              partitionedAttrs.herculesCI = "dev";
              partitions.dev.extraInputsFlake = ./dev;
              partitions.dev.module = { inputs, ... }: {
                imports = [
                  ./nix/development.nix
                  inputs.hercules-ci-effects.flakeModule
                  inputs.pre-commit-hooks-nix.flakeModule
                ];
              };
              ```

              `dev/flake.nix`:

              ```nix
              {
                description = "Private inputs for development purposes. These are used by the top level flake in the `dev` partition, but do not appear in consumers' lock files.";
                inputs = {
                  hercules-ci-effects.url = "github:hercules-ci/hercules-ci-effects";
                  pre-commit-hooks-nix.url = "github:cachix/pre-commit-hooks.nix";
                  # See https://github.com/ursi/get-flake/issues/4
                  pre-commit-hooks-nix.inputs.nixpkgs.follows = "";
                };

                # This flake is only used for its inputs.
                outputs = { ... }: { };
              }
              ```

              ## Caveats

              - A module in a partition can affect options that are not exported with `partitionedAttrs`. This will have an effect that is only observable in the attributes that are exported with `partitionedAttrs`, and not in the other flake attributes. This could be useful or surprising.

              - A flake used in `extraInputsFlake` is a separate flake, which means that you may have to duplicate e.g. a `nixpkgs` input for the purpose of `follows`. We don't have a way to override flake inputs after the effect.

              ## Explanation

              `imports` must be loaded eagerly by the module system, because any module can affect the contents and shape of `config`.
              Declaring `imports = [ foo ];` is simply not enough to know the effects of `foo` without getting `foo`'s attributes.

              Fortunately this fundamental limitation only applies one "layer" at a time. Every submodule has its own set of modules or `imports` and that allows us to still load modules lazily, as long as we provide the means for those modules to affect the root (here: the flake) in a controlled way. That is what this module does. It loads the "optional" modules into a separate submodule, and provides an option to load parts of that (sub)module evaluation into the root.

            '';
            installationDeclareInput = false;
            attributePath = [ "flakeModules" "partitions" ];
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
            menu.enable = false;
          };
      };
    };
}
