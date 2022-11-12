
# Module Arguments

The module system allows modules and submodules to be defined using plain
attribute sets, or functions that return attribute sets. When a module is a
function, various attributes may be passed to it.

# Top-level Module Arguments

Top-level refers to the module passed to `mkFlake`, or any of the modules
imported into it using `imports`.

The standard module system arguments are available in all modules and submodules. These are chiefly `config`, `options`, `lib`.

## `getSystem`

A function from [system](./system.md) string to the `config` of the appropriate `perSystem`.

## `moduleWithSystem`

A function that brings the `perSystem` module arguments.
This allows a module to reference the defining flake without introducing
global variables.

```nix
{ moduleWithSystem, ... }:
{
  nixosModules.default = moduleWithSystem (
    perSystem@{ config }:  # NOTE: only explicit params will be in perSystem
    nixos@{ ... }:
    {
      services.foo.package = perSystem.config.packages.foo;
      imports = [ ./nixos-foo.nix ];
    }
  );
}
```

## `withSystem`

Enter the scope of a system. Worked example:

```nix
{ withSystem, ... }:
{
  # perSystem = ...;

  nixosConfigurations.foo = withSystem "x86_64-linux" (ctx@{ pkgs, ... }:
    pkgs.nixos ({ config, lib, packages, pkgs, ... }: {
      _module.args.packages = ctx.config.packages;
      imports = [ ./nixos-configuration.nix ];
      services.nginx.enable = true;
      environment.systemPackages = [
        packages.hello
      ];
    }));
}
```

# `perSystem` module parameters

##  `pkgs`

Default: `inputs.nixpkgs.legacyPackages.${system}`.

Can be set via `config._module.args.pkgs`.

Example:

```nix
perSystem = { pkgs, ... }: {
  packages.hello = pkgs.hello;
};
```

## `inputs'`

The flake `inputs` parameter, but with `system` pre-selected. Note the last character of the name, `'`, pronounced _prime_.

`inputs.foo.packages.x86_64-linux.hello` -> `inputs'.foo.packages.hello`

How? `system` selection is handled by the extensible function [`perInput`](options/flake-parts.html#opt-perInput).

Example:

```nix
perSystem = { inputs', ... }: {
  packages.default = inputs'.foo.packages.bar;
};
```

## `self`

The flake `self` parameter, but with `system` pre-selected.

Example:

```nix
perSystem = { pkgs, self', ... }: {
  packages.hello = pkgs.hello;
  packages.default = self'.packages.hello;
};
```

## `system`

The [system](system.md) parameter, describing the architecture and platform of the host system (where the thing will run).

Example:

```nix
perSystem = { system, ... }: {
  packages.nixosDefaultPackages =
    let nixos = inputs.nixpkgs.lib.nixosSystem {
          modules = [ { nixpkgs.hostPlatform = system; } ];
        };
        checked = builtins.seq nixos.config.system.build.toplevel;
       # I have no idea why you would want this, but you do you
    in checked nixos.config.system.path;
};
```
