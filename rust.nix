
{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
   openblas
   gfortran
   cmake
   python312
   python312Packages.ipython
   python312Packages.matplotlib
   python312Packages.plotly
   python312Packages.pandas
   python312Packages.seaborn
   python312Packages.numpy
   python312Packages.scipy
   openssl
   pkg-config
   loco-cli
   sea-orm-cli
   sqlite
  ];
}
