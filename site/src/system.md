# Multi-platform: `system`

In Nix, "system" generally refers to the cpu-os string, such as `"x86_64-linux"`.

In Flakes specifically, these strings are used as attribute names, so that the
Nix CLI can find a derivation for the right platform.

Many things, such as packages, can exist on multiple systems. For these, use
the [`perSystem`](options/flake-parts.html#opt-perSystem) submodule.

Other things do not exist on multiple systems. Examples are the configuration
of a specific machine, or the execution of a deployment. These are not
written in `perSystem`, but in other top-level options, or directly into the
flake outputs' top level (e.g. [`flake.nixosConfigurations`](options/flake-parts.html#opt-flake.nixosConfigurations)).

Such top-level entities typically do need to read packages, etc that are defined
in `perSystem`. Instead of reading them from `config.flake.packages.<system>.<name>`,
it may be more convenient to bring all `perSystem` definitions for a system into
scope, using [`withSystem`](module-arguments.html#withsystem).

## Configuring Nixpkgs for NixOS

When using NixOS configurations with flake-parts, you have two approaches for configuring Nixpkgs settings like `allowUnfree`, overlays, or other `config` options:

### Approach 1: Configure Nixpkgs directly in NixOS

Let NixOS manage its own Nixpkgs configuration:

```nix
{ withSystem, ... }: {
  flake.nixosConfigurations.my-machine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ({ pkgs, ... }: {
        imports = [ ./configuration.nix ];

        nixpkgs.config.allowUnfree = true;
        nixpkgs.overlays = [ inputs.foo.overlays.default ];

        services.foo.package = withSystem pkgs.stdenv.hostPlatform.system (
          { config, ... }: # perSystem module arguments
          config.packages.foo
        );
      })
    ];
  };
}
```

This approach is straightforward and keeps the Nixpkgs configuration isolated to the NixOS system, while still allowing access to packages defined in `perSystem`.

Note that with this approach, `perSystem` has its own `pkgs` that is separate from and unaware of the NixOS-specific Nixpkgs configuration.

### Approach 2: Configure `pkgs` once in `perSystem`

Configure `pkgs` in `perSystem` and reuse it in your NixOS configurations using [`withSystem`](module-arguments.html#withsystem).

In a flake-parts module (e.g., `./nixos.nix`):

```nix
{ withSystem, inputs, ... }: {
  perSystem = { system, ... }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [ inputs.foo.overlays.default ];
      config = {
        allowUnfree = true;
      };
    };

    # Now use this configured pkgs in your packages, devShells, etc.
    packages.my-package = pkgs.hello;
  };

  flake.nixosConfigurations.my-machine = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      ./configuration.nix
      inputs.nixpkgs.nixosModules.readOnlyPkgs
      ({ config, ... }: {
        # Use the configured pkgs from perSystem
        nixpkgs.pkgs = withSystem config.nixpkgs.hostPlatform.system (
          { pkgs, ... }: # perSystem module arguments
          pkgs
        );
      })
    ];
  };
}
```

In your `flake.nix`:

```nix
{
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      imports = [ ./nixos.nix ];
    };
}
```

This approach centralizes your Nixpkgs configuration, ensuring that your development shells, packages, and NixOS configurations all use the same Nixpkgs configuration.

The `readOnlyPkgs` module makes the Nixpkgs configuration read-only, preventing other modules from accidentally overriding your carefully configured `pkgs`.
