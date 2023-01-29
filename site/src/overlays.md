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

## Defining an overlay with flake-parts

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

## Altered `perSystem` module arguments

In the context of an overlay, the `pkgs` module argument is defined as the "previous" or "super" argument of an overlay.

The `final` module argument is only defined when `easyOverlay` is imported. It is defined as the "final" or "self" argument. It is _also_ available outside the context of an `flake.overlays.default`, in which case its value is (also) equal to `pkgs` extended by the `overlayAttrs`.

## See also

 - [`perSystem.overlayAttrs`](options/flake-parts-easyOverlay.html#opt-perSystem.overlayAttrs)
