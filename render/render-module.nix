top@{ config, inputs, lib, flake-parts-lib, ... }:
let
  inherit (lib)
    mkOption
    types
    concatMap
    concatLists
    mapAttrsToList
    attrValues
    hasPrefix
    removePrefix
    ;

  failPkgAttr = name: _v:
    throw ''
      Most nixpkgs attributes are not supported when generating documentation.
      Please check with `--show-trace` to see which option leads to this `pkgs.${lib.strings.escapeNixIdentifier name}` reference. Often it can be cut short with a `defaultText` argument to `lib.mkOption`, or by escaping an option `example` using `lib.literalExpression`.
    '';

in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, lib, ... }:
    let
      cfg = config.render;
      inputs = config.render.officialFlakeInputs // top.inputs;

      pkgsStub = lib.mapAttrs failPkgAttr pkgs;

      fixups = { lib, flake-parts-lib, ... }: {
        options.perSystem = flake-parts-lib.mkPerSystemOption {
          config = {
            _module.args.pkgs = pkgsStub // {
              _type = "pkgs";
              inherit lib;
              formats = lib.mapAttrs
                (formatName: formatFn:
                  formatArgs:
                  let
                    result = formatFn formatArgs;
                    stubs =
                      lib.mapAttrs
                        (name: _:
                          throw "The attribute `(pkgs.formats.${lib.strings.escapeNixIdentifier formatName} x).${lib.strings.escapeNixIdentifier name}` is not supported during documentation generation. Please check with `--show-trace` to see which option leads to this `${lib.strings.escapeNixIdentifier name}` reference. Often it can be cut short with a `defaultText` argument to `lib.mkOption`, or by escaping an option `example` using `lib.literalExpression`."
                        )
                        result;
                  in
                  stubs // {
                    inherit (result) type;
                  }
                )
                pkgs.formats;
            };
          };
        };
      };

      eval = evalWith {
        modules = concatLists (mapAttrsToList (name: inputCfg: lib.optionals (!inputCfg.separateEval) (inputCfg.getModules inputCfg.flake)) cfg.inputs);
      };
      evalWith = { modules }: inputs.flake-parts.lib.evalFlakeModule
        {
          inputs = {
            inherit (inputs) nixpkgs;
            self = eval.config.flake // {
              outPath =
                throw "The `self.outPath` attribute is not available when generating documentation, because the documentation should not depend on the specifics of the flake files where it is loaded. This error is generally caused by a missing `defaultText` on one or more options in the trace. Please run this evaluation with `--show-trace`, and look for `while evaluating the default value of option` and add a `defaultText` to one or more of the options involved.";
            };
          };
        }
        {
          imports = modules ++ [
            fixups
          ];
          systems = [ (throw "The `systems` option value is not available when generating documentation. This is generally caused by a missing `defaultText` on one or more options in the trace. Please run this evaluation with `--show-trace`, look for `while evaluating the default value of option` and add a `defaultText` to the one or more of the options involved.") ];
        };

      opts = eval.options;

      coreOptDecls = config.render.inputs.flake-parts._nixosOptionsDoc.optionsNix;

      filterTransformOptions = { sourceName, sourcePath, baseUrl, coreOptDecls }:
        let sourcePathStr = toString sourcePath;
        in
        opt:
        let
          declarations = concatMap
            (decl:
              if hasPrefix sourcePathStr (toString decl)
              then
                let subpath = removePrefix sourcePathStr (toString decl);
                in [{ url = baseUrl + subpath; name = sourceName + subpath; }]
              else [ ]
            )
            opt.declarations;
        in
        if declarations == [ ] || (
          sourceName != "flake-parts" && coreOptDecls?${lib.showOption opt.loc}
        )
        then opt // { visible = false; }
        else opt // { inherit declarations; };


      inputModule = { config, name, ... }: {
        options = {
          flake = mkOption {
            type = types.raw;
            description = ''
              A flake.
            '';
            default = inputs.${name};
            defaultText = lib.literalExpression "inputs.\${name}";
          };

          sourcePath = mkOption {
            type = types.path;
            description = ''
              Source path in which the modules are contained.
            '';
            default = config.flake.outPath;
            defaultText = lib.literalExpression "config.flake.outPath";
          };

          title = mkOption {
            type = types.str;
            description = ''
              Title of the markdown page.
            '';
            default = name;
          };

          flakeRef = mkOption {
            type = types.str;
            description = ''
              Flake reference string that refers to the flake to import, used in the generated text for the installation instructions, see {option}`installation`.
            '';
            default =
              # This only works for github for now, but we can set a non-default
              # value in the list just fine.
              let
                match = builtins.match "https://github.com/([^/]*)/([^/]*)/blob/([^/]*)" config.baseUrl;
                owner = lib.elemAt match 0;
                repo = lib.elemAt match 1;
                branch = lib.elemAt match 2; # ignored for now because they're all default branches
              in
              if match != null
              then "github:${owner}/${repo}"
              else throw "Couldn't figure out flakeref for ${name}: ${config.baseUrl}";
            defaultText = lib.literalMD ''
              Determined from `config.baseUrl`.
            '';
          };

          isEmpty = mkOption {
            type = types.bool;
            description = ''
              Whether this input is empty, ie has no documented options.

              Normally this is indicative of a inaccurate tracking of declaration
              sources, or declaring options in `perSystem.config` instead of
              `mkPerSystemOption`.

              If your module really has no options of its own (ie only imports and config), set this to true.
            '';
            default = false;
          };

          preface = mkOption {
            type = types.str;
            description = ''
              Stuff between the title and the options.
            '';
            default = ''

              ${config.intro}

              ${config.installation}

            '';
            defaultText = lib.literalMD "`intro` followed by `installation`";
          };

          intro = mkOption {
            type = types.str;
            description = ''
              Introductory paragraph between title and installation.
            '';
          };

          installationDeclareInput = mkOption {
            type = types.bool;
            description = ''
              Whether to show how to declare the input.
            '';
            default = true;
          };

          installation = mkOption {
            type = types.str;
            description = ''
              Installation paragraph between installation and options.
            '';
            default =
              ''
                ## Installation

                ${if config.installationDeclareInput
                then ''
                  To use these options, add to your flake inputs:

                  ```nix
                  ${config.sourceName}.url = "${config.flakeRef}";
                  ```

                  and inside the `mkFlake`:
                ''
                else ''
                  To use these options, add inside the `mkFlake`:
                ''}

                ```nix
                imports = [
                  inputs.${config.sourceName}.${lib.concatMapStringsSep "." lib.strings.escapeNixIdentifier config.attributePath}
                ];
                ```

                Run `nix flake lock` and you're set.
              '';
            defaultText = lib.literalMD "Generated";
          };

          sourceName = mkOption {
            type = types.str;
            description = ''
              Name by which the source is shown in the list of declarations.
            '';
            default = name;
          };

          baseUrl = mkOption {
            type = types.str;
            description = ''
              URL prefix for source location links.
            '';
          };

          getModules = mkOption {
            type = types.functionTo (types.listOf types.raw);
            description = ''
              Get the modules to render.
            '';
            default = flake: [
              (builtins.addErrorContext "while getting modules for input '${name}'"
                (lib.getAttrFromPath config.attributePath flake)
              )
            ];
            defaultText = lib.literalMD "Derived from `config.attributePath`, `<name>`";
          };

          attributePath = mkOption {
            type = types.listOf types.str;
            description = ''
              Flake output attribute path to import.
            '';
            default = [ "flakeModule" ];
            example = [ "flakeModules" "default" ];
          };

          rendered = mkOption {
            type = types.package;
            description = ''
              A package containing the generated documentation page.
            '';
            readOnly = true;
          };

          _nixosOptionsDoc = mkOption {
            internal = true;
          };

          separateEval = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Whether to include this in the main evaluation.

              By default, all modules are evaluated together, except ones that enable this option.
            '';
          };

          filterTransformOptions = mkOption {
            default = filterTransformOptions;
            description = ''
              Function to customize the set of options to render for this input.

              This is mostly for overriding the default behavior, which excludes the options of the flake-parts module itself, unless it's the flake-parts core itself that's being rendered.
            '';
          };

          fixupAnchorsBaseUrl = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Replace same-page links without `opt-` prefix with this prefix.
            '';
          };

          menu = {
            title = mkOption {
              type = types.str;
              description = ''
                Title of the menu entry.
              '';
              default = config.title;
            };
            enable = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether to add this page to the navigation menu.

                Modules in the flake-parts repo disable this, as they're hardcoded into the menu.
              '';
            };
          };
        };
        config = {
          _nixosOptionsDoc = pkgs.nixosOptionsDoc {
            options =
              if config.separateEval
              then
                (evalWith {
                  modules = config.getModules config.flake;
                }).options
              else
                opts;
            documentType = "none";
            transformOptions = config.filterTransformOptions {
              inherit (config) sourceName baseUrl sourcePath;
              inherit coreOptDecls;
            };
            warningsAreErrors = true; # not sure if feasible long term
            markdownByDefault = true;
          };
          rendered =
            let
              checkEmpty =
                lib.throwIf
                  (config.isEmpty != (config._nixosOptionsDoc.optionsNix == { }))
                  (if config.isEmpty # ie expected
                  then "The input ${name} now has options. Please remove `isEmpty = true;` from the input."
                  else "Did not find any options to render for ${name}. If this is intentional, set `isEmpty = true;` on the input."
                  );
            in

            checkEmpty pkgs.stdenv.mkDerivation (finalAttrs: {
              name = "option-doc-${config.sourceName}";
              nativeBuildInputs = [ pkgs.libxslt.bin pkgs.pandoc ];
              optionsDoc = config._nixosOptionsDoc.optionsMarkdown.overrideAttrs {
                anchorPrefix = "opt-";
              };
              inherit (config) title preface;
              passAsFile = [ "preface" ];
              buildCommand = ''
                mkdir $out
                cat >$out/options.md <<EOF
                # $title

                $(cat $prefacePath)

                ## Options

                $(cat $optionsDoc)

                EOF
                # cat -n $out/options.md | grep caddy
                # set -x
                ${lib.optionalString (config.fixupAnchorsBaseUrl != null) ''
                  sed -i 's|(\(\\#[^o)][^p)][^t)][^-)][^)]*\))|(${config.fixupAnchorsBaseUrl}\1)|g' $out/options.md
                ''}
              '';
              passthru.file = finalAttrs.finalPackage + "/options.md";
            });
        };
      };
    in
    {
      options = {
        render = {
          inputs = mkOption {
            description = "Which modules to render.";
            type = types.attrsOf (types.submodule inputModule);
          };
          officialFlakeInputs = mkOption {
            type = types.raw;
            description = ''
              The inputs from the `flake.parts-website` flake.

              This supplements the `inputs` module argument when the rendering module is used in a different flake.
            '';
            readOnly = true;
          };
        };
      };
      config = {
        packages = lib.mapAttrs' (name: inputCfg: { name = "generated-docs-${name}"; value = inputCfg.rendered; }) cfg.inputs // {
          generated-docs =
            pkgs.runCommand "generated-docs"
              {
                passthru = {
                  inherit config;
                  inherit eval;
                  # This won't be in sync with the actual nixosOptionsDoc
                  # invocations, but it's useful for troubleshooting.
                  allOptionsPerhaps = (pkgs.nixosOptionsDoc {
                    options = opts;
                  }).optionsNix;
                };
                passAsFile = [ "menu" ];
                menu =
                  lib.concatStringsSep
                    "\n"
                    (lib.filter
                      (x: x != "")
                      (lib.mapAttrsToList
                        (name: inputCfg:
                          lib.optionalString inputCfg.menu.enable
                            "    - [${inputCfg.menu.title}](options/${name}.md)"
                        )
                        cfg.inputs
                      )
                    );
              }
              ''
                mkdir $out
                ${lib.concatStringsSep "\n"
                  (lib.mapAttrsToList
                    (name: inputCfg: ''
                      cp ${inputCfg.rendered.file} $out/${name}.html
                    '')
                    cfg.inputs)
                }
                cp $menuPath $out/menu.md
              '';
        };
      };
    });
}
