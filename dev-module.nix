{ lib, inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
  ];

  perSystem =
    {
      self',
      config,
      pkgs,
      ...
    }:
    let
      ignoreRevsFile = ".git-blame-ignore-revs";
    in
    {
      devShells.default = pkgs.mkShell {
        nativeBuildInputs = [
          pkgs.hci
          pkgs.netlify-cli
          pkgs.pandoc
          pkgs.mdbook
          pkgs.lychee
        ];
        shellHook = ''
          # Configure this repo to ignore certain revisions in git blame
          git config blame.ignoreRevsFile ${ignoreRevsFile}
          ${config.pre-commit.installationScript}
        '';
      };

      treefmt = {
        projectRootFile = "flake.nix";

        programs = {
          nixfmt.enable = true;
          prettier.enable = true;
        };

        settings = {
          on-unmatched = "fatal";
          global.excludes = [
            "*.gitignore"
            "*.png"
            "*.svg"
            "*.toml"
            "site/_redirects"
            "site/src/highlight.js"
            ignoreRevsFile
          ];
        };
      };

      pre-commit = {
        settings = {
          hooks.treefmt.enable = true;
        };
      };
    };
}
