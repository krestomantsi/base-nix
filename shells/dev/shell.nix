# Odin + Rust + Python (uv) dev shell — non-flake, no `flake.nix` needed.
#
#   nix-shell ~/base-nix/shells/dev/shell.nix
#   # or copy/symlink it into a project:
#   ln -s ~/base-nix/shells/dev/shell.nix ~/myproject/shell.nix && cd ~/myproject && nix-shell
#
# One shell with all three toolchains, so a repo that mixes Odin (with an
# editor LSP), Rust and a uv-managed Python side just works:
#
#   odin / ols              -> compiler + language server (dev-2026-05)
#   rustup                  -> cargo/rustc; install the toolchain once:
#                              rustup toolchain install stable
#                              rustup default stable
#                              rustup component add rust-analyzer clippy rustfmt
#   uv / python312          -> `uv sync`, `uv run ...`; uv's downloaded CPython
#                              works because the host enables programs.nix-ld
#
# Editor/multiplexer: nvim (with nvim-treesitter -> tree-sitter CLI) is in the
# shell, so `nvim` inside herdr-app uses the same version as the system one.
#
# Toolchain versions come from <nixpkgs> (your channel, or the host's pinned
# nixpkgs when you run this on the Framework host). Use `--pure` if you want
# the shell to fully own the environment.

{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "odin-rust-uv";

  nativeBuildInputs = with pkgs; [
    pkg-config
    gcc
    binutils
    gnumake
    cmake
  ];

  buildInputs = with pkgs; [
    # ---- odin ----
    odin
    ols
    just

    # ---- rust ----
    rustup

    # ---- python / uv ----
    uv
    python312

    # ---- nvim + multiplexer tooling ----
    neovim
    tree-sitter
    ripgrep
    fd
    fzf

    # ---- things the three toolchains link against ----
    openssl
    zlib
    sqlite
    curl
    raylib # vendored odin packages (vendor:raylib)
    libGL
    libx11
    libxrandr
    libxi
    libxcursor
    libxinerama
    wayland
    libxkbcommon
  ];

  shellHook = ''
    export CARGO_HOME="''${CARGO_HOME:-$HOME/.cargo}"
    export RUSTUP_HOME="''${RUSTUP_HOME:-$HOME/.rustup}"
    # raylib in nixpkgs is X11-only; it runs through XWayland on GNOME Wayland.
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ pkgs.libGL pkgs.libx11 ]}:''${LD_LIBRARY_PATH:-}"

    echo "odin-rust-uv shell"
    echo "  odin:  $(odin version)"
    echo "  ols:   ${pkgs.ols.version}"
    echo "  uv:    $(uv --version)"
    toolchain="$(rustup toolchain list 2>/dev/null | grep -v 'no installed toolchains' | head -1)"
    if [ -z "$toolchain" ]; then
      echo "  rust:  no toolchain yet -> rustup toolchain install stable && rustup default stable"
    else
      echo "  rust:  $toolchain"
    fi
  '';
}
