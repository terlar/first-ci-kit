{ config, lib, ... }:

{
  options.jobSets = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        description = "Job Set configuration";
        modules = [ ./job-set ];
        specialArgs.rootConfig = config;
      }
    );
    default = { };
    description = "Job Sets to group jobs.";
  };
}
