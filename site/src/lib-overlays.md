# Library Overlays

You can define a library overlay by passing a list or attribute set of library overlays to
`mkFlake`:
```nix
outputs = inputs@{ flake-parts, ...}:
  flake-parts.lib.mkFlake {
	inherit inputs;
	libOverlays = [
	  {
		my-flake = {
		  identity = x: x;
		};
	  }
	];
  } ({lib, ...}: {
	systems = lib.my-flake.identity [ "x86_64-linux" ];
  })

```

These overlays will be applied in the `lib` argument passed to any
flake modules included in this evaluation of `mkFlake`. They work
similarly to nixpkgs overlays, in the sense that they can have access
to both the "predecessor" `lib` upon which they are building or to the
"final" fully-resolved `lib`. They can also have access to the current
flake's inputs if they wish. The overlay function should be curried
must take some suffix of this parameter list (including the empty
list): `input`, `final`, `prev`.

## Namespacing

Unless you are applying a polyfill, you are heavily encouraged to
namespace any functions you graft onto `lib` with the name of your
flake. This was done in the example (assuming that we are working in a
flake called `my-flake`). Namespacing substantially reduces the
likelihood that two different overlays will clash when applied to the
same `lib`.
