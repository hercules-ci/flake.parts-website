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
          git config blame.ignoreRevsFile .git-blame-ignore-revs
          ${config.pre-commit.installationScript}
        '';
      };

      treefmt = {
        projectRootFile = "flake.nix";
        programs = {
          nixfmt.enable = true;
        };
      };

      pre-commit = {
        settings = {
          hooks.fmt = {
            enable = true;
            entry = lib.getExe self'.formatter;
          };
        };
      };
    };
}
