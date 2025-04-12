{
  config,
  lib,
  ...
}:

let
  inherit (lib) types;
in
{
  options.jobs = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submoduleWith {
        description = "Job configuration";
        modules = [ ./job ];
        specialArgs.rootConfig = config;
      }
    );
    default = { };
    description = "Jobs to run in pipeline.";
  };
}
