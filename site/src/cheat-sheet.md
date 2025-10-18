# Cheat Sheet

Flake-parts offers a couple of ways to access the same thing. This gives you
freedom to pick the most convenient syntax for a use case.

This page is for you to get a feel for what's what.

## Get a locally defined package

Getting the locally defined `hello` package on/for an `x86_64-linux` host:

### On the command line

```console
nix build .#hello
```

### In `perSystem`

```nix
config.packages.hello
```

```nix
self'.packages.hello
```

The [`self'`](module-arguments.html#self) parameter is derived from the flake `self`, which may benefit from evaluation caching in the future.

The `config` parameter is conceptually simpler and lets you access all options inside `perSystem`, including unexposed ones if you're into defining such options.

### In the top level

> **Note**
>
> Anything you can do at the top level, you can do in `perSystem` as well, although you may have to `@` match those module arguments.
>
> For example, change the top level function header to e.g. `toplevel@{ config, ... }: /*...*/` so you can access `toplevel.config` despite plain `config` being shadowed by `perSystem = { config, ... }: /*...*/`.

Examples:

```nix
(getSystem "x86_64-linux").packages.hello
```

```nix
withSystem "x86_64-linux" ({ config, ... }:
  config.packages.hello
)
```

```nix
self.x86_64-linux.packages.hello
```

```nix
allSystems.x86_64-linux.packages.hello
```

`allSystems` may not be future proof if Nix starts to allow building for all systems. An opened up system is incompatible with enumerated systems as required by an attribute set.
