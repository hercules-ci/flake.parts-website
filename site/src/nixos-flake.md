# System management with nix flakes

If your goal is to control your machine using [nix flakes](https://nixos.wiki/wiki/Flakes), this guide is for you.

Machines come in different flavors, you may already be using nixos, another linux distribution or mac (with arm or intel architecture). You can manage them all using "the flake way".

Be sure to have nix installed in your system.

Let's start!

## Terminology

- `host`: a machine, like a desktop computer, a laptop or a server in the cloud
- `hostname`: name given to the machine, use `hostname -s` to retrieve it in unix systems
- `templates`: in this context they refer to nix templates

## Getting started

All of our configurations will be conveniently housed within a `nixos-config` folder, irrespective of the underlying system being used.

No matter the system used, we are gonna create a folder that will contain all the configurations for the host system. You have the option to back up the project on a Git platform such as GitHub, GitLab, Gittea, and others. Additionally, you can easily extend it to multiple hosts if needed.

If you publish your configuration to github, please add the label `flake-parts-nixos-flake` to make it easier to find.

Let's begin

```sh
mkdir ~/nixos-config
cd ~/nixos-config
```

And we are going to initialize the fantastic [nixos-flake](https://github.com/srid/nixos-flake) which uses itself flakes-parts.

```sh
nix flake init -t github:srid/nixos-flake
```

This will initialize a flake with support for nixos, nix-darwin and home-manager combined.

If you'd rather initialize only a macos, or another linux distribution, check the [nixos-flake docs](https://zero-to-flakes.com/nixos-flake/templates).

## Configuring different systems

### On nixos

Your nix configuration should be on `/etc/nixos`, you should have something like:

```console
$ ls /etc/nixos
configuration.nix  hardware-configuration.nix
```

Let's copy the existing system there.

```sh
TARGET="~/nixos-config/hosts/$(hostname -s)"
mkdir -p "$TARGET"
cp -r /etc/nixos "$TARGET"
```

Now it's time for you to dig into the `flake.nix`, update the `TODO`s with your `username` and `hostname`, and
finally, import the configurations that we previously copied.

The last step is to activate the flake:

```sh
nix run .#activate
```

### On other linux distributions

If you are using a non-nixos linux distribution, you probably should use the `home` template (you can add other systems later). And you'll use nix as a replacement for your dotfiles, with the advantage of having a declarative language, with declarative aliases, packages from nixpkgs and many more configurations.

```sh
nix flake init -t github:srid/nixos-flake#home
```

Configure at will.

And finally, activate it:

```sh
nix run .#activate-home
```

### On Mac

If you are on an Intel Mac, change `mkARMMacosSystem` to `mkIntelMacosSystem` and run

```sh
nix run .#activate
```

## Folder structure

You can use this set up as a starting point for a multi-machine and multi-user configuration for your fleet of machines.

```sh
nixos-config/
├── hardware/
│   ├── sd-image/
│   └── dell-xps13.nix # example of a specific hardware
├── home/
│   └── default.nix # shared home config
├── hosts/
├── nix-darwin/
│   └── default.nix
├── nixos/
│   └── default.nix
├── users/
│   ├── config.nix
│   └── default.nix
├── flake.lock
└── flake.nix
```

inside the `hosts` you'd create a "host" combining a user + home + nixos* + nix-darwin* + hardware\*

\* optional, depends on your needs

## Getting help

For questions related to flake-parts head to the [flake-parts discussions](https://github.com/hercules-ci/flake-parts/discussions) on github.

For questions related to nixos-flake head to the [nixos-flake discussions](https://github.com/srid/nixos-flake/discussions) on github.


## Resources

- https://github.com/srid/nixos-config
- https://github.com/lovesegfault/nix-config
- https://nixos-and-flakes.thiscute.world/nixos-with-flakes/modularize-the-configuration
