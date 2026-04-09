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
      type = types.lazyAttrsOf types.raw;
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
      apply = lib.unique;
      default = [ ];
      description = "List of job names associated with the job set";
    };

    tags = lib.mkOption {
      type = types.listOf types.str;
      apply = lib.unique;
      default = [ ];
      description = "List of tags associated with the job set";
    };

    github-actions = {
      reusableWorkflow = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          When true, generate this job set as a standalone reusable workflow file
          instead of inlining its jobs into the main ci.yml.
        '';
      };
    };
  };
}
