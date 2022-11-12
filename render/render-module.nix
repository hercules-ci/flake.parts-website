{ config, inputs, lib, flake-parts-lib, ... }:
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

in
{
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, pkgs, lib, ... }:
    let
      cfg = config.render;

      eval = inputs.flake-parts.lib.evalFlakeModule
        {
          self = { inputs = { inherit (inputs) nixpkgs; }; };
        }
        {
          imports = concatLists (mapAttrsToList (name: inputCfg: inputCfg.getModules inputCfg.flake) cfg.inputs);
        };

      opts = eval.options;

      filterTransformOptions = { sourceName, sourcePath, baseUrl }:
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
        if declarations == [ ]
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
          };

          sourcePath = mkOption {
            type = types.path;
            description = ''
              Source path in which the modules are contained.
            '';
            default = config.flake.outPath;
          };

          title = mkOption {
            type = types.str;
            description = ''
              Title of the markdown page.
            '';
            default = name;
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
            default = flake: [ (builtins.addErrorContext "while getting modules for input '${name}'" flake.flakeModule) ];
          };

          rendered = mkOption {
            type = types.package;
            description = ''
              Built Markdown docs.
            '';
            readOnly = true;
          };

          _nixosOptionsDoc = mkOption { };
        };
        config = {
          _nixosOptionsDoc = pkgs.nixosOptionsDoc {
            options = opts;
            documentType = "none";
            transformOptions = filterTransformOptions {
              inherit (config) sourceName baseUrl sourcePath;
            };
            warningsAreErrors = true; # not sure if feasible long term
            markdownByDefault = true;
          };
          rendered = pkgs.runCommand "option-doc-${config.sourceName}"
            {
              nativeBuildInputs = [ pkgs.libxslt.bin pkgs.pandoc ];
              inputDoc = config._nixosOptionsDoc.optionsDocBook;
              inherit (config) title;
            } ''
            xsltproc --stringparam title "$title" \
              -o options.db.xml ${./options.xsl} \
              "$inputDoc"
            mkdir $out
            pandoc --verbose --from docbook --to html options.db.xml >$out/options.html;
          '';
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
        };
      };
      config = {
        packages = lib.mapAttrs' (name: inputCfg: { name = "generated-docs-${name}"; value = inputCfg.rendered; }) cfg.inputs // {
          generated-docs =
            pkgs.runCommand "generated-docs"
              { }
              ''
                mkdir $out
                ${lib.concatStringsSep "\n"
                  (lib.mapAttrsToList
                    (name: inputCfg: ''
                      cp ${inputCfg.rendered}/options.html $out/${name}.html
                    '')
                    cfg.inputs)
                }
              '';
        };
      };
    });
}
