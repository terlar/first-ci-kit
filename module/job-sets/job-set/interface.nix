{ lib, ... }:

let
  inherit (lib) types;

  needsType = types.submoduleWith {
    description = "Job set needs configuration";
    modules = [
      {
        options = {
          jobSet = lib.mkOption {
            type = types.str;
            description = "Name of the needed job set.";
          };
        };
      }
    ];
  };
in
{
  options = {
    jobDefaults = lib.mkOption {
      type = types.deferredModule;
      default = { };
      description = "Configuration added to all the jobs within the job set.";
    };

    needs = lib.mkOption {
      type = types.listOf needsType;
      default = [ ];
      description = "Job Sets needed by the Job Set.";
    };

    jobs = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of job names associated with the job set";
    };
  };
}
