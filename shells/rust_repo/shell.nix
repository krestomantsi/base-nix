# ~/rust_repo/shell.nix — dev shell.
#
#   cd ~/rust_repo && nix-shell        (or: nix-shell --pure)
#
# Covers what the workspace actually needs:
#   - intel-mkl-src / ndarray-linalg[blas]  -> MKLROOT points at nixpkgs' MKL
#   - netcdf + hidefix(netcdf)              -> libnetcdf + hdf5 + pkg-config
#   - sea-orm (sqlx-sqlite, sqlx-postgres)  -> bundled sqlite, no libpq needed
#   - 4 x Trunk.toml web projects           -> trunk + wasm32 target
#   - just / bacon / cargo-wizard           -> task runner + dev loop
#   - uv + python                           -> pyproject.toml
#
# Rust itself comes from rustup (Cargo.toml wants 1.94 / edition 2024). Once:
#   rustup toolchain install stable && rustup default stable
#   rustup target add wasm32-unknown-unknown

{ pkgs ? import <nixpkgs> { config.allowUnfree = true; } }:

let
  mkl = pkgs.mkl;
in
pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    cmake
    gcc
    gnumake
  ];

  buildInputs = with pkgs; [
    # rust
    rustup
    # native deps
    openssl
    netcdf
    hdf5
    zlib
    sqlite
    # MKL (unfree, hence the pkgs override above)
    mkl
    # tooling
    just
    bacon
    cargo-nextest
    cargo-wizard
    sea-orm-cli
    # wasm frontends
    trunk
    wasm-bindgen-cli
    binaryen
    # python side
    uv
    nodejs
  ];

  # intel-mkl-src uses MKLROOT instead of downloading Intel's tarball.
  MKLROOT = "${mkl}";
  LD_LIBRARY_PATH = "${mkl}/lib";

  shellHook = ''
    export CARGO_HOME="''${CARGO_HOME:-$HOME/.cargo}"
    echo "rust_repo shell: rustup toolchain, MKLROOT=$MKLROOT"
    echo "first run: rustup toolchain install stable && rustup target add wasm32-unknown-unknown"
  '';
}
