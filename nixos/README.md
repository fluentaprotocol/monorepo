# NixOS - the ultimate Linux experience

This repository contains the NixOS configuration for my personal machines. It is
based on the [NixOS](https://nixos.org) operating system, which is a Linux distribution
built on top of the Nix package manager. The configuration is declarative and
version-controlled, which makes it easy to reproduce and share. It is also
extensible, which allows me to easily add new packages, services, and
configuration options.

## Installation

To install NixOS, follow the [official installation instructions](https://nixos.org/manual/nixos/stable/index.html#sec-installation).

## Usage

Before you begin, make sure you have a backup of your data. The NixOS configuration
is declarative, which means that it will overwrite your existing configuration.
If you make a mistake, you can always roll back to a previous configuration.

To use this configuration, clone `workstation` folder content to `/etc/nixos`.
Adjust the `configuration.nix` file to your needs and the `hardware-configuration.nix` to match your hardware.

To apply the configuration, run:

```sh
sudo nixos-rebuild switch --flake /etc/nixos
```

This will build and activate the new configuration. If you encounter any errors,
you can roll back to the previous configuration by running:

```sh
sudo nixos-rebuild boot --rollback
```

System profiles are persisted in `/nix/var/nix/profiles/system-*`. You can list
them with:

```sh
ls -l /nix/var/nix/profiles
```

To remove ALL old profiles, run:

```sh
sudo nix-collect-garbage --delete-old
```

You can also use `shell.nix` files to create development environments. To enter
a development environment, run:

```sh
nix-shell
```

### Other useful commands that I used during the exploration

```sh
sudo nix flake init --template github:vimjoyer/flake-starter-config
sudo nix flake update
nix search nixpkgs <searchterm>
man configuration.nix
man home-configuration.nix
nixos-rebuild test
nix-collect-garbage --delete-older-than 1d
sudo nixos-rebuild build-vm .#<hostname>
```

### Resources

[search.nixos.org](https://search.nixos.org/)
[Home Manager Option Search](https://mipmip.github.io/home-manager-option-search/)
[manix](https://github.com/lecoqjacob/manix)
[Nixpkgs GitHub Repository](https://github.com/nixos/nixpkgs)
[YouTube series](https://www.youtube.com/watch?v=a67Sv4Mbxmc&list=PLko9chwSoP-15ZtZxu64k_CuTzXrFpxPE)

## System Information

You can copy the `.config` folder to your home directory to get the same configuration.

```sh
cp -r .config ~/
```

There is installed `conky` to display system information. To start it, run:

```sh
conky -c ~/.config/conky/conky.conf
```
