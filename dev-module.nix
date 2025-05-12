{
  perSystem =
    { config, pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.nixfmt-rfc-style
          pkgs.pre-commit
          pkgs.hci
          pkgs.netlify-cli
          pkgs.pandoc
          pkgs.mdbook
          pkgs.lychee
        ];
        shellHook = ''
          # Configure this repo to ignore certain revisions in git blame
          git config blame.ignoreRevsFile .git-blame-ignore-revs
          ${config.pre-commit.installationScript}
        '';
      };
      pre-commit = {
        settings = {
          hooks.nixfmt-rfc-style.enable = true;
        };
      };
    };
}
