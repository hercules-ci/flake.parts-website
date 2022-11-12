{ inputs, ... }: {
  perSystem = { config, self', inputs', pkgs, lib, ... }: {
    packages = {
      siteContent = pkgs.stdenvNoCC.mkDerivation {
        name = "site";
        nativeBuildInputs = [ pkgs.mdbook ];
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
          mdbook build --dest-dir $out

          echo '<html><head><script>window.location.pathname = window.location.pathname.replace(/options.html$/, "") + "options/flake-parts.html"</script></head><body><a href="options/flake-parts.html">to the options</a></body></html>' \
            >$out/options.html

          runHook postBuild
        '';
        dontInstall = true;
      };
    };
  };
}
