# Overlays

Overlays in Nixpkgs allow the customization of the entire package set in a consistent manner. For example, if you set a library's attribute in an overlay, this change will be applied to all packages that previously depended on that attribute. This is in contrast with the way the Flake `packages` attribute works. Such definitions do not feed back into the Nixpkgs package set.

Advantages of overlays:

- The original attribute won't be around anymore. This almost guarantees that
  the original value won't be used anywhere else.
- The dependencies are more coherent, resulting in fewer "diamond dependency" conflicts

Advantages of the flake `packages` attribute without `inputs.<input>.follows`:

- A package definition won't interfere with other packages.
- The packages will be used with the dependencies that its CI built it with, resulting in fewer build problems.

Advantages of the flake `packages` attribute with `inputs.<input>.follows`:

- A package definition won't interfere with other packages.
- The dependencies are more coherent, resulting in fewer "diamond dependency" conflicts

Neither option is perfect.

## Consuming an overlay

Flake parts does not yet come with an endorsed module that initializes the `pkgs` argument.

You may initialize it manually; for example:

```nix
perSystem = { system, ... }: {
  _module.args.pkgs = import inputs.nixpkgs {
    inherit system;
    overlays = [
      inputs.foo.overlays.default
      (final: prev: {
        # ... things you need to patch ...
      })
    ];
    config = { };
  };
};
```

## Defining an overlay

While overlays are about packages, and therefore dependent on the choice of `system`, they are not defined under a system attribute. Instead they are in a top level attribute.

The reason for this is that they are conceptually defined as a function of not just `system`, but of a package set that includes `system`. Putting them in a `${system}` attribute would be conceptually redundant, and it would bother users of the overlay.

If an overlay needs a system string, it should usually reach for `prev.stdenv.hostPlatform.system`.

```
final: prev: {
  systemStringFile = prev.writeText "system-string"
    prev.stdenv.hostPlatform.system;
}
```

A manually defined overlay (more on automation later), can make use of `perSystem` as follows:

```nix
{ withSystem, ... }: {
  flake.overlays.my-overlay = final: prev:
    withSystem prev.stdenv.hostPlatform.system (
      # perSystem parameters. Note that perSystem does not use `final` or `prev`.
      { config, ... }: {
        my-package = config.packages.my-package;
      });
}
```

Note that such a usage of `perSystem` may introduce packages from the locked inputs of the overlay-defining flake into a completely different version of Nixpkgs. This may or may not be desirable as discussed in the introduction.

A more integrated method that repurpose the `pkgs` module argument in `perSystem` is available in the [`easyOverlay`] module, which is the topic of the next section.

## An overlay for free with flake-parts

While it is possible to define an [overlay](options/flake-parts.html#opt-flake.overlays) manually, flake-parts offers a module that derives an overlay from the `perSystem` module.

Here's a flake module that defines `overlays.default` to an overlay of the shape `final: prev: { my-package = ...; }`.

```nix
{
  imports = [
    inputs.flake-parts.flakeModules.easyOverlay
  ];
  perSystem = { config, pkgs, final, ... }: {
    overlayAttrs = {
      inherit (config.packages) my-package;
    };
    packages.my-package = /* ... */;
  };
}
```

### Altered `perSystem` module arguments

In the context of an overlay, the `pkgs` module argument is defined as the "previous" or "super" argument of an overlay.

The `final` module argument is only defined when [`easyOverlay`] is imported. It is defined as the "final" or "self" argument. It is _also_ available outside the context of an `flake.overlays.default`, in which case its value is (also) equal to `pkgs` extended by the [`overlayAttrs`].

## See also

- [`easyOverlay`]
- [`perSystem.overlayAttrs`]

[`easyOverlay`]: options/flake-parts-easyOverlay.md
[`overlayAttrs`]: options/flake-parts-easyOverlay.md#opt-perSystem.overlayAttrs
[`perSystem.overlayAttrs`]: options/flake-parts-easyOverlay.md#opt-perSystem.overlayAttrs
