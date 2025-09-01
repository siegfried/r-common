{
  description = "R for Quants";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    traderrr = {
      url = "github:siegfried/traderrr";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      traderrr,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-darwin"
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          R = pkgs.rWrapper.override {
            packages = [
              (pkgs.callPackage traderrr { })
              (pkgs.rPackages.lightgbm.overrideAttrs (old: {
                buildInputs = old.buildInputs ++ [ pkgs.llvmPackages.openmp ];
              }))
              (pkgs.rPackages.xgboost.overrideAttrs (old: {
                buildInputs = old.buildInputs ++ [ pkgs.llvmPackages.openmp ];
              }))
            ]
            ++ (with pkgs.rPackages; [
              dplyr
              dbplyr
              DBI
              RPostgres
              readr
              lubridate
              tidyr
              stringr
              purrr
              workflows
              ranger
              tune
              yardstick
              recipes
              dials
              parsnip
              butcher
              optparse
              hardhat
              future
              doFuture
              bonsai
              janitor
              textrecipes
              glmnet
              vip
              devtools
              languageserver
            ]);
          };
        in
        {
          inherit R;

          default = self.packages.${pkgs.system}.R;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              self.packages.${system}.R
              pkgs.curl
            ];
            shellHook = ''
              R
            '';
          };
        }
      );

    };
}
