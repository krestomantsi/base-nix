# ~/yggdrasil/shell.nix — dev shell.
#
#   cd ~/yggdrasil && nix-shell
#   ./build_server.sh
#
# Covers what the repo actually needs:
#   - odin compiler                          -> pkgs.odin
#   - external/sqlite3/lib_build/build.sh    -> cc + ar (gcc + binutils)
#   - vendor:raylib (14 files)               -> raylib + compiled raygui + GL/X11/Wayland headers
#   - remote_curl_posix.odin "system:curl"   -> libcurl from pkgs.curl
#   - pyproject.toml (cartopy, PyQt6, ...)   -> uv (nix-ld makes uv's CPython work)
#   - justfile                               -> just
#
# raylib in nixpkgs is X11-only, so the GUI runs through XWayland on GNOME
# Wayland. That works because the host sets services.xserver.enable = true.

{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    pkg-config
    gcc
    binutils
  ];

  buildInputs = with pkgs; [
    # compiler + language tooling
    odin
    just
    sqlite
    # linked by the vendored odin packages
    curl
    raylib
    (pkgs.callPackage ../common/raygui.nix { }) # system:raygui (not header-only)
    # raylib/GL/X11/Wayland runtime + headers
    libGL
    libx11
    libxrandr
    libxi
    libxcursor
    libxinerama
    wayland
    libxkbcommon
    # python side
    uv
  ];

  shellHook = ''
    echo "yggdrasil shell: $(odin version)"
    echo "build: ./build_server.sh   (sqlite amalgamation + odin build)"
    echo "python: uv sync && uv run python ..."
  '';
}
