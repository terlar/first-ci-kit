{ lib, ... }:

let
  inherit (lib) types;
in
{
  options.jobSets = lib.mkOption {
    type = types.lazyAttrsOf (
      types.submoduleWith {
        description = "Job Set configuration";
        modules = [ ./job-set ];
      }
    );
    default = { };
    description = "Job Sets to group jobs.";
  };
}
