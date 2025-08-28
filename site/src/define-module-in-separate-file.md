# Define a Module in a Separate File

To avoid writing huge files, you'll want to separate some logic into modules.

When you do so, you'll notice that you've cut access to the lexical scope. You can't access any of the variables in `flake.nix` anymore.

This problem has two possible solutions.

## Factor it out

In short, write an inline module in `flake.nix` (or in a flake module), that `imports` the separate module file and also forms a bridge between the `flake.nix` scope and the option values. This way the majority of the module can be in a separate file.

In the separate file, replace all variables that would come from the lexical scope by new options and reference those through `config`. In `flake.nix` fill in the missing defaults.

Example:

`nixos-module.nix`

```nix
{ lib, config, ... }: {
  options = {
    services.foo = {
      package = mkOption {
        defaultText = lib.literalMD "`packages.default` from the foo flake";
      };
    };
  };
  config = ...;
}
```

Flake module:

```nix
{ withSystem, ... }: {
  flake.nixosModules.default = { pkgs, ... }: {
    imports = [ ./nixos-module.nix ];
    services.foo.package = withSystem pkgs.stdenv.hostPlatform.system ({ config, ... }:
      config.packages.default
    );
  };
}
```

For your module users' overriding needs, it's best to make the options as specific as possible; e.g. not a `foo.flake` option, but `foo.package`.
You'll find that most modules only need one or two such options.

## `importApply`

The `importApply` function can pass extra variables to a module to import.

Instead of loading a file containing a module, it loads a file containing _a function to_ a module, and applies it.

`nixos-module.nix`

```nix
{ localFlake, withSystem }:
{
  lib,
  config,
  pkgs,
  ...
}:
{
  options = {
    services.foo = {
      package = mkOption {
        default = withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }: config.packages.default
        );
        defaultText = lib.literalMD "`packages.default` from the foo flake";
      };
    };
  };
  config = ... use localFlake ...;
}
```

Flake module:

```nix
{ flake-parts-lib, self, withSystem, ... }:
let
  inherit (flake-parts-lib) importApply;
in
{
  flake.nixosModules.default = importApply ./nixos-module.nix { localFlake = self; inherit withSystem; };
}
```

## See Also

- [Dogfooding a Reusable Flake Module](dogfood-a-reusable-module.md), which helps avoid an infinite recursion.
