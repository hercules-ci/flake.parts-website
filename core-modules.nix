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
      };
    };
}
