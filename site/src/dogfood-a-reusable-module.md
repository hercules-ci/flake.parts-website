# Dogfood a Reusable Module

_to dogfood: test one's own product by using it for your own purposes_

You can distribute reusable module logic through flakes using flake attributes, and that includes [`flakeModules`](options/flake-parts-flakeModules.html#opt-flake.flakeModules).
However, importing from `self` is not possible, because such an import could affect the `self` attribute set.
To use your own exported module, you have to reference it directly.

```
┌─────────┐   ┌───────────────────────────────────┐
│ imports │   │ config.flake.flakeModules.default │
└─────┬───┘   └─────────────────┬─────────────────┘
      │                         │
      │      ┌──────────────────┘
      │      │
┌─────▼──────▼─────┐
│ flake-module.nix │
└──────────────────┘
```

If your module does not need anything from the local flake's lexical scope, you might implement the references in the diagram above.
But if you do need to reference, say, a package from your local flake, then you need to apply one of the solutions from [Define a Module in a Separate File](define-module-in-separate-file.md).
Instead of the arrows joining at the file name, we'll need a `let` binding.

```
┌─────────┐   ┌───────────────────────────────────┐
│ imports │   │ config.flake.flakeModules.default │
└─────┬───┘   └─────────────────┬─────────────────┘
      │                         │
      │       ┌─────────────────┘
      │       │
┌─────▼───────▼─────────┐
│ let flakeModule = ... │
└─────────┬─────────────┘
          │
          │
          │
┌─────────▼────────┐
│ flake-module.nix │
└──────────────────┘
```

## Example with `importApply`

Here's an example of how this looks using the [`importApply` technique](define-module-in-separate-file.md#importapply).
This flake shows how to export a flake module that references its own flake, instead of just the user's flake (which would be available in the module arguments).
The example only demonstrates the principle, by reexporting a locally defined package in the user's flake.

`flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } ({ withSystem, flake-parts-lib, ... }:
    let
      inherit (flake-parts-lib) importApply;
      flakeModules.default = importApply ./flake-module.nix { inherit withSystem; };
    in
    {
      imports = [
        flakeModules.default
        # inputs.foo.flakeModules.default
      ];
      systems = [ "x86_64-linux" "aarch64-darwin" ];
      perSystem = { pkgs, ... }: {
        packages.default = pkgs.hello;
      };
      flake = {
        inherit flakeModules;
      };
    });
}
```

`flake-module.nix`:

```nix
# The importApply argument. Use this to reference things defined locally,
# as opposed to the flake where this is imported.
localFlake:

# Regular module arguments; self, inputs, etc all reference the final user flake,
# where this module was imported.
{ lib, config, self, inputs, ... }:
{
  perSystem = { system, ... }: {
    # A copy of hello that was defined by this flake, not the user's flake.
    packages.greeter = localFlake.withSystem system ({ config, ... }:
      config.packages.default
    );
  };
}
```

The ["Factor it out" technique](define-module-in-separate-file.md#factor-it-out) is equally applicable; replace `importApply` by an inline module.
