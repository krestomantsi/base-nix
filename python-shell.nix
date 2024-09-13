{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
   cudatoolkit
   python311
   python311Packages.jax
   #python311Packages.jaxlib-bin
   python311Packages.jaxlibWithCuda
   python311Packages.flax
   python311Packages.ipython
   python311Packages.matplotlib
   python311Packages.plotly
   python311Packages.pandas
   python311Packages.seaborn
   python311Packages.tqdm
   python311Packages.scikitlearn
   python311Packages.openpyxl
  ];
}
