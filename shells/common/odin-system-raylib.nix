# Patch nixpkgs' Odin package so its rlgl bindings use the system raylib library.
# nixpkgs already patches vendor/raylib/raylib.odin this way, but the matching
# x86_64 import in vendor/raylib/rlgl/rlgl.odin still points to a removed
# bundled archive under ODIN_ROOT/share/vendor/raylib/linux/.
{ pkgs }:

pkgs.odin.overrideAttrs (old: {
  postPatch = (old.postPatch or "") + ''
    substituteInPlace vendor/raylib/rlgl/rlgl.odin \
      --replace-fail '"../linux/libraylib.so.620" when RAYLIB_SHARED else "../linux/libraylib.a",' \
                     '"system:raylib",'
  '';
})
