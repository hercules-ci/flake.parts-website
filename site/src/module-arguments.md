# Module Arguments

The module system allows modules and submodules to be defined using plain attribute sets, or functions that return attribute sets.
When a module is a function, the module system and flake-parts pass various attributes to it.
These attributes are called _module arguments_.

This page documents the available arguments.

Note that if you use the `args@{ ... }` or `args:` syntax, you only receive the arguments you explicitly name in the function signature; see [below](#how-module-function-arguments-work) for details.

# General Module Arguments

These arguments are available in all modules and submodules, provided by the standard Nix module system.

See the [NixOS manual](https://nixos.org/manual/nixos/unstable/#sec-writing-modules) for an introduction to the module system.

## `config`

The values of the current module scope, containing the merged result of all option definitions from all modules.

In top-level modules, `config` contains the entire flake configuration. In `perSystem` modules, it contains configuration that's specialized towards the given `system`.

## `options`

The option declarations of the current module scope. This is primarily useful for inspecting option metadata or creating references to options in documentation.

`"${options.foo}"` renders a full option path towards `foo`.

## `lib`

The Nixpkgs library functions, taken from flake-parts' `nixpkgs-lib` input.

Commonly used for utility functions like `lib.mkIf`, `lib.mkOption`, `lib.types`, and many others.

See the [Nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable/#id-1.4) for documentation of available functions.

For the `nixpkgs-lib` input, you may specify a flake that only contains `lib`, or a whole Nixpkgs flake. By default, just `lib` gives you slightly faster shell tab completion as of writing.

To promote modularity and not create unnecessary, "strange" dependency constraints on `lib`, you are recommended not to override it. You may select a different version of it using Flake [`follows`](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake.html#flake-inputs).

## More

See the [Nixpkgs manual](https://nixos.org/manual/nixpkgs/unstable/#module-system-module-arguments) for documentation of more rarely used general module arguments.

# Top-level Module Arguments

Top-level refers to the module passed to `mkFlake`, or any of the modules imported into it using `imports`.

## `getSystem`

A function from a [system](./system.md) string to the `config` of the appropriate `perSystem`.

## `moduleWithSystem`

A function that brings the `perSystem` module arguments.
This allows a module to reference the defining flake without introducing
global variables.

```nix
{ moduleWithSystem, ... }:
{
  nixosModules.default = moduleWithSystem (
    perSystem@{ config, ... }:  # NOTE: only explicitly named parameters will be in perSystem; see below
    nixos@{ ... }:
    {
      services.foo.package = perSystem.config.packages.foo;
      imports = [ ./nixos-foo.nix ];
    }
  );
}
```

## `withSystem`

Enter the scope of a system. Example:

```nix
{ withSystem, inputs, ... }:
{
  # perSystem = { ... }: { config.packages.hello = ...; };

  flake.nixosConfigurations.foo = withSystem "x86_64-linux" (ctx@{ config, inputs', ... }:
    inputs.nixpkgs.lib.nixosSystem {
      # Expose `packages`, `inputs` and `inputs'` as module arguments.
      # Using specialArgs permits use in `imports`.
      # Note: if you publish modules for reuse, do not rely on specialArgs, but
      # on the flake scope instead. See also https://flake.parts/define-module-in-separate-file.html
      specialArgs = {
        packages = config.packages;
        inherit inputs inputs';
      };
      modules = [
        # This module could be moved into a separate file; otherwise we might
        # as well have used ctx.config.packages directly.
        ({ config, lib, packages, pkgs, ... }: {
          imports = [ ./nixos-configuration.nix ];
          services.nginx.enable = true;
          environment.systemPackages = [
            # hello package defined in perSystem
            packages.hello
          ];
        })
      ];
    });
}
```

# `perSystem` Module Parameters

## `pkgs`

Default: `inputs.nixpkgs.legacyPackages.${system}`.

Set via `config._module.args.pkgs`.

Example:

```nix
perSystem = { pkgs, ... }: {
  packages.hello = pkgs.hello;
};
```

## `inputs'`

The flake `inputs` parameter, but with `system` pre-selected. Note the last character of the name, `'`, pronounced _prime_.

`inputs.foo.packages.x86_64-linux.hello` -> `inputs'.foo.packages.hello`

`system` selection is handled by the extensible function [`perInput`](options/flake-parts.html#opt-perInput).

Example:

```nix
perSystem = { inputs', ... }: {
  packages.default = inputs'.foo.packages.bar;
};
```

## `self'`

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

# How Module Function Arguments Work

The Nix module system determines which arguments to pass to a module function by using `builtins.functionArgs`.
This means only the parameters you explicitly name in your function signature will be available.

## Examples

**This doesn't capture all module arguments:**

```nix
perSystem =
  # A perSystem definition is also a module
  args: {
    # args will NOT contain module arguments like pkgs, self', inputs', etc.
    # despite being defined:
    _module.args.pkgs = import ...;
    packages.example = args.pkgs.hello;  # Error: attribute 'pkgs' missing
  };
```

**This does work:**

```nix
perSystem = { pkgs, self', inputs', ... }: {
  # Named arguments are available
  packages.example = pkgs.hello;
  packages.fromOther = inputs'.other-flake.packages.something;
};
```

**This works, but is not recommended:**

```nix
perSystem = args@{ pkgs, self', inputs', ... }: {
  # Not recommended, as the availability of `args` can lead to confusion
  packages.example = args.pkgs.hello;
  packages.fromOther = args.inputs'.other-flake.packages.something;
};
```

## Obtaining All Module Arguments

In the context of `perSystem`, you can obtain all module arguments using the internal option `allModuleArgs`:

```nix
perSystem = { config, ... }: {
  # Access all perSystem module arguments
  packages.example = config.allModuleArgs.pkgs.hello;

  # This includes custom arguments defined with _module.args
  packages.custom = config.allModuleArgs.myCustomArg;

  # You can even access the entire set of module arguments
  foo = config.allModuleArgs;
};
```

`allModuleArgs` is available because flake-parts provides it for the `perSystem` submodule evaluation, similar to how it works with the `withSystem` function.

This is not provided for the top level flake-parts configuration; only `perSystem`.

## Rationale

Nix evaluates the attribute set passed to a function like `args@{ foo, ... }` strictly (before returning the function body) in order to efficiently check the function call's argument, to make sure it's an attribute set, and that it has the listed attributes, like `foo`.

This means it needs to evaluate the argument before returning the function body.
However, the module system would face a circular dependency when passing the module arguments using a straightforward function call: it can't know all available module argument names until it has evaluated the modules, but it can't evaluate module functions without passing them their arguments.

To solve this, the module system uses `builtins.functionArgs` to inspect what arguments a module function expects, and constructs the argument set accordingly. If a module argument is not defined in any module or `specialArgs`, the attribute for it is present, but instead of a value, evaluating it will throw an exception.

In a normal Nix function invocation, an `args@` binding would bind to the original argument set, which, as discussed, is not the complete set of module arguments.

Unfortunately, the module system cannot know whether such a binding is present in the function definition, so it cannot warn about this potential issue.
