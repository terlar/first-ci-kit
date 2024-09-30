{
  flake-parts-lib,
  lib,
  withSystem,
  ...
}:

let
  inherit (flake-parts-lib) mkPerSystemOption;
  inherit (lib) mkOption types;
in
{
  options.perSystem = mkPerSystemOption (
    { pkgs, ... }:
    {
      options.first-ci-kit.pipelines = mkOption {
        type = types.lazyAttrsOf (
          types.submoduleWith {
            modules = [ ./module ];
            specialArgs = {
              inherit pkgs;
            };
          }
        );
        default = { };
        description = "Pipelines for CI.";
      };
    }
  );

  config = {
    flake.tests.first-ci-kit = withSystem "x86_64-linux" ({ pkgs, ... }: pkgs.callPackage ./module/tests { });

    perSystem =
      { pkgs, ... }:
      {
        packages.module-docs = pkgs.callPackage ./packages/module-docs {
          moduleRoot = ./module;
        };
      };
  };
}
