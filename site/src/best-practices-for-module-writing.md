
# Best Practices for Module Writing

Like in NixOS, writing a configuration is quite different from writing a reusable module.

In a configuration, you may take shortcuts which have little impact, but shortcuts in a reusable module lead to surprises for your module's users.

## Do not make assumptions about `inputs`

The inputs are controlled by the user, so your module should make no assumption about which inputs are present.
This way, the user is free to, for example, bundle up their inputs into a distribution, such as a company platform module.

## Use `perSystem`

When integrating an existing library, it might be easy to add its options in the top level namespace only, as it might already expose a whole-flake interface. However, as most build and test work is done in `perSystem`, users expect to be able to use it in that context. See also [perSystem first (custom flake attribute)](define-custom-flake-attribute.html#persystem-first).

## Bundle with existing flake

Most modules are about some piece of software that it integrates. Ideally the flake module is bundled into the same flake. This simplifies the wiring that users have to do, especially when they want to use a patched version. It's also a bit more efficient as far as fetching is concerned.

## Do not use overlay general option names

Most modules will put all their options inside a "namespace" named after their module instead. This way, option path collisions are unlikely to occur.

For example: `perSystem.treefmt.programs`, not `perSystem.programs`.
