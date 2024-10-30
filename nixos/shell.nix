let
  # Pinned nixpkgs, deterministic. Last updated: 2/12/21.
  pkgs = import (fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/a58a0b5098f0c2a389ee70eb69422a052982d990.tar.gz";
      sha256 = "sha256:1dmnm6r67q75ql96hag851438ybqlx21vfn309ir3z6n08a2qsfs";
    }) {system = "x86_64-linux";};

  # Rolling updates, not deterministic.
  # pkgs = import (fetchTarball("channel:nixpkgs-unstable")) {};
in pkgs.mkShell {
  buildInputs = [ pkgs.cargo pkgs.rustc ];
}
