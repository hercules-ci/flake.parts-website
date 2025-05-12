{
  perSystem = { config, pkgs, ... }: {
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
