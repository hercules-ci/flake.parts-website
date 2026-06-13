# Nix

This is a brief introduction to nix, in the context of flake-parts.

## What is nix?

When you read `nix` somewhere, it may refer to one or more of the following concepts:

1. An GNU/Linux distribution, called [NixOS](https://nixos.org/)
2. A language, called the [Nix Language](https://nixos.org/manual/nix/stable/language/index.html)
3. A package manager, see [package management](https://nixos.org/manual/nix/stable/package-management/package-management.html) or [install nix](https://nix.dev/tutorials/install-nix).

NixOS makes use of the package manager and the nix language.
But you don't need to run nixos to use the package manager, or the language.

## What are Nixpkgs?

[Nixpkgs](https://nixos.org/manual/nixpkgs/stable/) are one of the biggest collections of packages.
It's written in the Nix Language, and it's used by the nix package manager. Check the [supported platforms](https://nixos.org/manual/nix/stable/installation/supported-platforms.html).

You can search for packages on [search.nixos.org/packages](https://search.nixos.org/packages)

## How does the nix language look?

The Nix Language is, in a way, **similar** to JSON with support for functions.

```nix
{
  string = "hello";
  integer = 1;
  float = 3.141;
  bool = true;
  null = null;
  list = [ 1 "two" false ];
  flat.objects.user = {
    name = "foo";
  };
}
```

```console
$ nix eval -f sample.nix
{ bool = true; flat = { objects = { user = { name = "foo"; }; }; }; float = 3.141; integer = 1; list = [ 1 "two" false ]; null = null; string = "hello"; }
```

You can even output JSON!

```console
$ nix eval --json -f sample.nix
{
  "bool": true,
  "flat": { "objects": { "user": { "name": "foo" } } },
  "float": 3.141,
  "integer": 1,
  "list": [1, "two", false],
  "null": null,
  "string": "hello"
}
```

And a function:

```nix
{ name }: {
  hello = "My name is ${name}, running on ${builtins.currentSystem}";
}
```

```console
$ nix-instantiate --eval hello.nix --argstr name jon -A hello
"My name is jon, running on x86_64-darwin"
```

To learn more, head to

- [nix.dev's nix language tutorial](https://nix.dev/tutorials/first-steps/nix-language) or;
- [A tour of Nix](https://nixcloud.io/tour/?id=1).

## What are people using nix for?

- To package applications (with flakes)
- A declarative CI ([hercules-ci](https://hercules-ci.com/))
- Control a fleet of machines (using [nixops](https://nixos.wiki/wiki/NixOps), [deploy-rs](https://github.com/serokell/deploy-rs))
- Manage dotfiles
- As a configuration or template language ([terranix](https://terranix.org/))

See more in [awesome-nix](https://github.com/nix-community/awesome-nix).

## What are nix flakes?

Nix flakes are one the newest features in the nix ecosystem, built on top of the experience with nix and its ecosystem.

The main idea is to have a file called `flake.nix` with a set of [standardized outputs](https://nixos.wiki/wiki/Flakes#Output_schema). You can also reference to other flakes, and a `flake.lock` file is used to guarantee reproducibility.

Still **considered experimental**, flakes enable packaging applications in a distributed manner.

- [nix flake manual](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html)
- [nix.dev flakes](https://nix.dev/concepts/flakes)

## What is flake-parts for?

flake-parts makes writing flakes easier, by establishing a way of working with [system](./system.md).
On top of that, it makes easier to write and reuse modules.
