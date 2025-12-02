{ inputs, flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    {
      config,
      pkgs,
      system,
      ...
    }:
    let
      pkgs-mdbook = inputs.nixpkgs-mdbook-0-5.legacyPackages.${system};
    in
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
            pkgs-mdbook.mdbook
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
    }
  );
}
