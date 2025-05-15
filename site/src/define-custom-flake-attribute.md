# Defining a custom flake output attribute

## When should I declare a custom flake output?

With flakes, most of the time, you can use the attribute names suggested by the Nix CLI, NixOS, etc, which already have options in flake-parts, or existing modules you can import.

However, if you're doing something that doesn't fit those labels, you may consider adding a custom attribute to the flake outputs. Your custom attribute may not be easy to use with the existing tools, but that may be expected, if you're writing a new tool or something else that's novel.

## How do I do it?

If your custom output attribute is a one-off because you need to do something special in a single project, all you have to do is define a value in the [`flake` option](options/flake-parts.html#opt-flake).

However, if you want it to be reusable and integrate well, you should declare an option for it, and you could perhaps provide a bit of support logic if that makes sense to do.

## `perSystem` first

<!-- TODO: expand this to stand alone examples and explain it better. -->

Integrating with `perSystem` is highly recommended, because that's where users expect things like packages to be defined. You can bring things that are defined in `perSystem` to the flake outputs in the same way [`packages.nix`](https://github.com/hercules-ci/flake-parts/blob/main/modules/packages.nix) does it.

If your application doesn't follow the same pattern, but you want users to define things in [`perSystem`](options/flake-parts.html#opt-perSystem), you may read the top level `config.allSystems` (internal) option. You can read it in the definition for a new option in the [`flake`](options/flake-parts.html#opt-flake) submodule so that its value is added to the flake outputs.

## `config.flake`

[flake](options/flake-parts.html#opt-flake) is an RFC42-style module, which means that it both has options and it allows arbitrary attributes to be defined in the config, without having to declare an option first.
Declaring an option is recommended though, for the purposes of documentation, type checking, and allowing multiple config definitions to be merged into a single output value, if applicable.

## Get Help

This is an advanced use case. Feel free to ask questions in [#hercules-ci:matrix.org](https://matrix.to/#/#hercules-ci:matrix.org).
