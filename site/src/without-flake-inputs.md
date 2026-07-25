# Source `pkgs` and `lib` Without Flake Inputs

flake-parts reads Nixpkgs from a flake input by default, but it does not require one.
If your dependencies are pinned by [npins](https://github.com/andir/npins), [niv](https://github.com/nmattia/niv), or a hand-written `fetchTarball`, you can point flake-parts at those pins instead, whether or not the project has a `flake.nix` at all.

## Choosing `pkgs`

The `pkgs` argument in `perSystem` is a module argument, so you define it like any other:

```nix
perSystem = { system, ... }: {
  _module.args.pkgs = import sources.nixpkgs { inherit system; };
};
```

flake-parts' own definition is `inputs'.nixpkgs.legacyPackages.${system}`, wrapped in [`lib.mkOptionDefault`](https://nixos.org/manual/nixpkgs/unstable/#module-system-lib-mkOptionDefault).
A plain definition therefore wins on its own; you do not need `lib.mkForce`.

That default is also never forced when you override it, so the flake does not need a `nixpkgs` input in the first place:

```nix
{
  # No `nixpkgs` input; the pin lives in `npins/sources.json`.
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs@{ flake-parts, ... }:
    let sources = import ./npins;
    in flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" ];
      perSystem = { system, pkgs, ... }: {
        _module.args.pkgs = import sources.nixpkgs { inherit system; };

        packages.default = pkgs.hello;
      };
    };
}
```

`sources` is whatever your pinning tool returns; npins, niv and a plain `fetchTarball` are interchangeable here.
Because you call `import` yourself, this is also where Nixpkgs configuration goes, such as `config.allowUnfree = true` or an `overlays` list.

## Choosing `lib`

`lib` does not come from your `pkgs`. It comes from flake-parts' own `nixpkgs-lib` input, and as [Module Arguments](module-arguments.md#lib) explains, you are recommended not to override it.

When you do want the two to agree, and you have a `flake.nix`, use [`follows`](https://nix.dev/manual/nix/latest/command-ref/new-cli/nix3-flake.html#flake-inputs):

```nix
inputs.flake-parts.url = "github:hercules-ci/flake-parts";
inputs.flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";
```

Without a `flake.nix` there is no `follows`. [flake-compat](https://git.lix.systems/lix-project/flake-compat) evaluates flake-parts' `flake.nix` for you, and with the input override support from [flake-compat pull request 87](https://git.lix.systems/lix-project/flake-compat/pulls/87) it can substitute `nixpkgs-lib` as well:

```nix
let
  sources = import ./npins;

  flake-compat = import sources.flake-compat;

  flake-parts = (flake-compat { src = sources.flake-parts; }).overrideInputs {
    nixpkgs-lib = sources.nixpkgs;
  };
in
flake-parts.outputs.lib.mkFlake # ...
```

`overrideInputs` is not part of a released flake-compat yet, so until that pull request is merged, pin the branch it comes from.

## What Does Not Carry Over

The `inputs'` and `self'` module arguments are flake-only.
[`modules/perSystem.nix`](https://github.com/hercules-ci/flake-parts/blob/main/modules/perSystem.nix) builds `inputs'` by walking `self.inputs` and throws for any entry whose `_type` is not `"flake"`.
Two consequences:

- A pin from npins is a store path, not a flake, so it cannot be reached through `inputs'`.
- Only `self.inputs` is consulted. Adding an entry to the `inputs` you pass to `mkFlake` does not make it appear in `inputs'`.

Non-flake sources reach your modules through the module system instead.
Top-level modules can also take them through `mkFlake`'s `specialArgs`, but `_module.args` works in both scopes:

```nix
{
  _module.args.sources = sources;
  perSystem._module.args.sources = sources;
}
```

For the wider picture, see [Extend beyond Flakes](https://github.com/hercules-ci/flake-parts/issues/329).

## Complete Example

A project with no `flake.nix`, pinned entirely by npins:

```console
$ npins init --bare
$ npins add --name nixpkgs github NixOS nixpkgs --branch nixos-unstable
$ npins add --name flake-parts github hercules-ci flake-parts --branch main
# The pull request branch, until `overrideInputs` is merged into flake-compat.
$ npins add --name flake-compat git https://git.lix.systems/kiaragrouwstra/flake-compat --branch override-inputs
```

`default.nix`:

```nix
let
  sources = import ./npins;

  flake-compat = import sources.flake-compat;

  # flake-parts, with its own `nixpkgs-lib` input replaced by our pin.
  flake-parts = (flake-compat { src = sources.flake-parts; }).overrideInputs {
    nixpkgs-lib = sources.nixpkgs;
  };

  # flake-parts writes flake outputs, so it needs a `self`. Without a
  # `flake.nix` there is nothing to produce one, so make it by hand.
  self = {
    _type = "flake";
    outPath = ./.;
    inputs = { };
  };
in
flake-parts.outputs.lib.mkFlake { inputs = { inherit self; }; inherit self; } {
  systems = [ "x86_64-linux" ];
  perSystem = { system, pkgs, ... }: {
    _module.args.pkgs = import sources.nixpkgs { inherit system; };

    packages.default = pkgs.hello;
  };
}
```

```console
$ nix-build -A packages.x86_64-linux.default
```
