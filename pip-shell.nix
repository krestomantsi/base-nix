{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
   cudatoolkit
   python311
   python311Packages.jax
   python311Packages.jaxlib-bin
   #python311Packages.jaxlibWithCuda
   python311Packages.flax
   python311Packages.ipython
  ];
}
