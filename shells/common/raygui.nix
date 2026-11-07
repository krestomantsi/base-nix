# Odin's vendor:raylib bindings link system:raygui separately. Nixpkgs ships
# raygui as a header-only package, so compile its implementation into a library.
{ stdenv, lib, pkg-config, raylib, raygui }:

stdenv.mkDerivation {
  pname = "raygui-library";
  inherit (raygui) version;

  dontUnpack = true;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ raylib raygui ];

  buildPhase = ''
    runHook preBuild
    printf '#define RAYGUI_IMPLEMENTATION\n#include <raygui.h>\n' > raygui.c
    $CC -shared -fPIC $(pkg-config --cflags raylib raygui) \
      raygui.c -o libraygui.so $(pkg-config --libs raylib) -lm
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 libraygui.so "$out/lib/libraygui.so"
    runHook postInstall
  '';

  meta = {
    description = "Compiled raygui implementation for Odin's system library bindings";
    inherit (raygui.meta) homepage license;
    platforms = lib.platforms.linux;
  };
}
