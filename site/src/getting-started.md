# Getting Started

## New flake

If your project does not have a flake yet:

```console
nix flake init -t github:hercules-ci/flake-parts
```

## Existing flake

Otherwise, add the input,

```nix
flake-parts.url = "github:hercules-ci/flake-parts";
```

then slide `mkFlake` between your outputs function head and body,

```nix
outputs = inputs@{ flake-parts, ... }:
  # https://flake.parts/module-arguments.html
  flake-parts.lib.mkFlake { inherit inputs; } (top@{ config, withSystem, moduleWithSystem, ... }: {
    imports = [
      # Optional: use external flake logic, e.g.
      # inputs.foo.flakeModules.default
    ];
    flake = {
      # Put your original flake attributes here.
    };
    systems = [
      # systems for which you want to build the `perSystem` attributes
      "x86_64-linux"
      # ...
    ];
    perSystem = { config, pkgs, ... }: {
      # Recommended: move all package definitions here.
      # e.g. (assuming you have a nixpkgs input)
      # packages.foo = pkgs.callPackage ./foo/package.nix { };
      # packages.bar = pkgs.callPackage ./bar/package.nix {
      #   foo = config.packages.foo;
      # };
    };
  });
```

Now you can start using the flake-parts options.
