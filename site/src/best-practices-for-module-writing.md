# Best Practices for Module Writing

Like in NixOS, writing a configuration is quite different from writing a reusable module.

In a configuration, you may take shortcuts which have little impact, but shortcuts in a reusable module lead to surprises for your module's users.

## Do not make assumptions about `inputs`

The inputs are controlled by the user, so your module should make no assumption about which inputs are present.
This way, the user is free to, for example, bundle up their inputs into a distribution, such as a company platform module.

## Do not traverse `inputs`

By scanning through all the `inputs`, you cause two kinds of problems

- You trigger the fetching of all direct dependencies, even though some may not need to be fetched.
- You are making an assumption about the role in which an input is used.

By recursing into inputs, you make the problem literally **exponentially** worse:

- Your module logic becomes susceptible to changes deep inside your dependencies' dependencies. Whereas you might have gotten away with an assumption about the role of direct dependencies, making the same assumptions about dependencies and dependencies' dependencies is unlikely to work out well.
- You trigger the fetching of potentially all transitive dependencies. Instead of a performance inconvenience, we now have a ecosystem-wide scaling problem.

Also note that even if you don't explicitly recurse into the transitive inputs, this behavior still arises if your inputs don't adhere to the rule.

Furthermore it has been observed that lock files can grow indefinitely when mutually dependent flakes don't use `follows` to remove the older version of themselves from the inputs graph.

## Use `perSystem`

When integrating an existing library, it might be easy to add its options in the top level namespace only, as it might already expose a whole-flake interface. However, as most build and test work is done in `perSystem`, users expect to be able to use it in that context. See also [perSystem first (custom flake attribute)](define-custom-flake-attribute.html#persystem-first).

## Bundle with existing flake

Most modules are about some piece of software that it integrates. Ideally the flake module is bundled into the same flake. This simplifies the wiring that users have to do, especially when they want to use a patched version. It's also a bit more efficient as far as fetching is concerned.

## Do not use overly general option names

Most modules will put all their options inside a "namespace" named after their module instead. This way, option path collisions are unlikely to occur.

For example: `perSystem.treefmt.programs`, not `perSystem.programs`.
