{ lib, pkgs, ... }:

let
  inherit (lib) types;
in
{
  options.jobs = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submoduleWith {
        description = "Job configuration";
        modules = [ ./job ];
        specialArgs = {
          inherit pkgs;
        };
      }
    );
    default = { };
    description = "Jobs to run in pipeline.";
  };
}
