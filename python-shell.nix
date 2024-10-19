{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell {
  buildInputs = with pkgs; [
   cudatoolkit
   python312
   python312Packages.jax
   #python321Packages.jaxlib-bin
   python312Packages.jaxlibWithCuda
   python312Packages.flax
   python312Packages.ipython
   python312Packages.matplotlib
   python312Packages.plotly
   python312Packages.pandas
   python312Packages.seaborn
   python312Packages.tqdm
   python312Packages.scikitlearn
   python312Packages.openpyxl
  ];
}
