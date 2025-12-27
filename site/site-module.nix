{ inputs, flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      ...
    }:
    {

      /*
        Check the links, including anchors (not currently supported by mdbook)

        Separate check so that output can always be inspected with browser.
      */
      checks.linkcheck =
        pkgs.runCommand "linkcheck"
          {
            nativeBuildInputs = [ pkgs.lychee ];
            site = config.packages.default;
            config = (pkgs.formats.toml { }).generate "lychee.toml" {
              include_fragments = true;
              remap = [
                "https://flake.parts file://${config.packages.default}"
              ];
            };
          }
          ''
            echo Checking $site
            lychee --offline --config $config $site || {
              # When verbose (-v), https://github.com/NixOS/nix/issues/10289
              r=$?; sleep 1; return $r;
            }

            touch $out
          '';

      packages = {
        default = pkgs.stdenvNoCC.mkDerivation {
          name = "site";
          nativeBuildInputs = [
            pkgs.mdbook
          ];
          src = ./.;
          buildPhase = ''
            runHook preBuild

            {
              while read ln; do
                case "$ln" in
                  *end_of_intro*)
                    break
                    ;;
                  *)
                    echo "$ln"
                    ;;
                esac
              done
              cat src/intro-continued.md
            } <${inputs.flake-parts + "/README.md"} >src/README.md

            mkdir -p src/options
            for f in ${config.packages.generated-docs}/*.html; do
              cp "$f" "src/options/$(basename "$f" .html).md"
            done
            sed -e 's/<!-- module list will be concatenated to the end -->//g' -i src/SUMMARY.md
            cat ${config.packages.generated-docs}/menu.md >> src/SUMMARY.md
            mdbook build --dest-dir $out
            cp _redirects $out

            echo '<html><head><script>window.location.pathname = window.location.pathname.replace(/options.html$/, "") + "options/flake-parts.html"</script></head><body><a href="options/flake-parts.html">to the options</a></body></html>' \
              >$out/options.html

            runHook postBuild
          '';
          dontInstall = true;
        };
      };

      apps =
        let
          opener = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
          openApp = {
            type = "app";
            program = "${pkgs.writeShellScript "open-manual" ''
              path="${config.packages.default}/index.html"
              if ! ${opener} "$path"; then
                echo "Failed to open manual with ${opener}. Manual is located at:"
                echo "$path"
              fi
            ''}";
            meta.description = "Open this version of the flake.parts website in your browser";
          };
        in
        {
          open = openApp;
          default = openApp;
        };
    }
  );
}
