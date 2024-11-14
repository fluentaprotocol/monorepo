{config,pkgs, ...}: let
  username = "john";
#  rust-package = import (fetchTarball {
#      url = "https://github.com/NixOS/nixpkgs/archive/a58a0b5098f0c2a389ee70eb69422a052982d990.tar.gz";
#      sha256 = "sha256:1dmnm6r67q75ql96hag851438ybqlx21vfn309ir3z6n08a2qsfs";
#    }) {system = "x86_64-linux";};

in {
  imports = [
    ./packages
  ];

  fonts.fontconfig.enable = true;

  nixpkgs = {
    config = {
      # Allow unfree packages
      allowUnfree = true;

      permittedInsecurePackages = [
      #    "openssl-1.1.1v"
          "python-2.7.18.8"
      ];
    };
  };


  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
      #vim
      #wget
      #w3m
      #dmenu
      # neofetch
      # neovim
      #starship
      #bat
      # celluloid
      # chatterino2
      # clang-tools_9
      # dunst
      # efibootmgr
      # elinks
      # eww
      # feh
      flameshot
      # flatpak
      # floorp
      # fontconfig
      # freetype
      # fuse-common
      # gcc
      gcc_multi
      rustup
      nodejs_22
      bun
      gimp
      git
      # github-desktop
      # gnome.gnome-keyring
      # gnugrep
      # gnumake
      # gparted
      # gnugrep
      # grub2
      # hugo
      # kitty
      # libverto
      # luarocks
      # lxappearance
      # mangohud
      # neovim
      pkg-config
      nfs-utils
      # ninja
      # nodejs
      # nomacs
      openssl
      os-prober
      # nerdfonts
      # pavucontrol
      # picom
      # polkit_gnome
      # powershell
      # protonup-ng
      python3Full
      python.pkgs.pip
      python312Packages.pyzbar
      ffmpeg_7-full
      #qemu
      # ripgrep
      # rofi
      # sxhkd
      # st
      # stdenv
      # synergy
      # swaycons
      #terminus-nerdfont
      tldr
      trash-cli
      unzip
      variety
      virt-manager
      xclip  
      vscode
      libsForQt5.kleopatra
      keepassxc
      authenticator
      remmina
      mullvad-browser
      vlc
      obs-studio
      obsidian
      libreoffice-qt6-fresh
      wget
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/john/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

}
