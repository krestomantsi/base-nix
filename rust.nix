
{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
   cmake
   #cargo 
   #rustc
   python311
   python311Packages.ipython
   python311Packages.matplotlib
   python311Packages.plotly
   python311Packages.pandas
   python311Packages.seaborn
  ];
}