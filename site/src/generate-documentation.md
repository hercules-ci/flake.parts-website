# Generate Documentation

The module system supports the generation of documentation.
This guide shows how to avoid common solutions to documentation errors, and how to publish documentation here on [flake.parts](https://flake.parts).

## Add `description` to all options

Make sure all options have a `description` or if necessary mark them as `internal = true;`.

## Make sure non-trivial defaults have `defaultText`

Documentation generation works by evaluating your module in a slightly different way, just to extract documentation, while some of the option values are not valid.
This particularly affects `default` in your `mkOption` calls. Consider the following example:

```nix
contents = mkOption {
  description = ''
    A derivation that produces the contents.
  '';
  # no default
};
publishPath = mkOption {
  description = ''
    The contents to publish.
  '';
  default = config.contents;
};
```

In this situation, the documentation for `publishPath` requires that we evaluate `contents`, which is unset and therefore results in an error.
The solution is to add `defaultText`:

```nix
publishPath = mkOption {
  description = ''
    The contents to publish.
  '';
  default = config.contents;
  defaultText = lib.literalExpression "contents";
  # Alternatively, if you don't want to put non-trivial code here, use markdown:
  # defaultText = lib.literalMD "the value of the `contents` option";
};
```

## Make sure to use `mkPerSystemOption`

While it is possible to declare options using `config.perSystem`, or just `perSystem = { ... }: { options = /* ... */; }`, these modules will not be picked up by the documentation generation.

As a rule of thumb, the documentation generator only traverses through `options` and not through `config`.

To make docs available, use this syntax:

```nix
{ lib, self, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption ({ config, ... }: {
    /* ... put perSystem module body here ... */
  });
}
```

## Publish on flake.parts

1. Check that you've added a license to the project. <details><blockquote>Without a license attached, people will be able to look at it, and fork it (because both of that is allowed via GitHub's own Terms of Service), but they may not use it in their own projects, modify it or otherwise do anything else with it. You alone have the exclusive copyright.</blockquote><br/> &mdash; [GitHub Guide on Open Source Licensing](https://github.com/readme/guides/open-source-licensing) </details>
1. Clone `https://github.com/hercules-ci/flake.parts-website`, or for via ssh: `git@github.com:hercules-ci/flake.parts-website`
1. Add your flake to the `inputs` in `flake.nix`
1. Define the details in `render.inputs` in `flake.nix`.
   See [flake.parts-website reference docs](options/flake.parts-website.md) for option details.
1. `nix build -L --show-trace`
1. Open a pull request

## Get help

If you're still getting an error, or a bad output, consider opening a draft PR.

## Private documentation

The `flake.parts-website` flake exposes modules for reuse in your own flake, and could be used to internally publish documentation for private modules.
These modules are subject to change, but also slow moving.

```console
$ nix flake init -t flake.parts-website#private-site
```
