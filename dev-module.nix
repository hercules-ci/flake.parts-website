{
  perSystem = { config, pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.nixpkgs-fmt
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
        hooks.nixpkgs-fmt.enable = true;
      };
    };
  };
}
