{
  config,
  lib,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      # operator libs
      numpy
      jax jaxlibWithCuda flax 
      scipy
      pandas openpyxl
      #scikit-learn

      # visualisation
      matplotlib seaborn plotly


      ipython # i hate this
    ]))
    poetry
  ];
}
