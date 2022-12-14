
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
  flake-parts.lib.mkFlake { inherit inputs; } {
    flake = {
      # Put your original flake attributes here.
    };
    systems = [
      # systems for which you want to build the `perSystem` attributes
      "x86_64-linux"
      # ...
    ];
    perSystem = { config, ... }: {
    };
  };
```

Now you can start using the flake-parts options.
