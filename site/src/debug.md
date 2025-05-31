# Explore and debug option values

Sometimes the public interface of a flake is not enough. To inspect all option values, you can enable [`debug`](options/flake-parts.html#opt-debug) and explore otherwise private values with the repl.

## Start debugging

1.  Add `debug = true;`
    Example:

    ```nix
    {
      debug = true;

      systems = /* ... */;
      perSystem = /* ... */;
    }
    ```

2.  Load the flake

    ```
    $ nix repl
    nix-repl> :lf .

    ```

## Inspect the perSystem configuration for your machine

```
nix-repl> currentSystem.allModuleArgs.pkgs.stdenv.hostPlatform.system
"x86_64-linux"

```

## Inspect the perSystem configuration for a different system type

```
nix-repl> debug.allSystems.armv7l-linux.allModuleArgs.pkgs.stdenv.hostPlatform.system
"armv7l-linux"

```

## Inspect a top level option

```
nix-repl> debug.systems
[ "x86_64-linux" "aarch64-darwin" ]

```

## Where is a per system value defined?

```
nix-repl> currentSystem.options.pre-commit.settings.files
[ "/nix/store/pqp5kwdihyyymfnqq9sk9jsm9xw2lw6s-source/dev-module.nix, via option perSystem" "/nix/store/4wl7k0dp7cjyc4nxy5cm9wdb8jshlg0j-source/flake-module.nix" ]

```

## Where is a top level value defined?

```
nix-repl> debug.options.system.files
[ "/nix/store/3na6c6mmyw2yf5chzwwwrp54b8yf96ry-source/flake.nix" ]

```

## Where is a top level option declared?

```
nix-repl> debug.options.systems.declarations
[ "/nix/store/3na6c6mmyw2yf5chzwwwrp54b8yf96ry-source/modules/perSystem.nix" ]

```

## See also

- The [`debug` option](options/flake-parts.html#opt-debug) reference.
