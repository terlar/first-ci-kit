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

      reusableWorkflowFile = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          When set, the caller job uses this path as `uses:` instead of the
          auto-generated `.github/workflows/<name>.yml`. No workflow file is
          generated for this job-set. Requires reusableWorkflow = true.
        '';
      };

      reusableWorkflowInputs = lib.mkOption {
        type = types.attrsOf types.anything;
        default = { };
        description = ''
          Inputs to pass to the reusable workflow via `with:`. Only used when
          reusableWorkflowFile is set.
        '';
      };

      callerExtraNeeds = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Extra job names to add to the caller job's `needs:` list, beyond those
          derived from the job-set's own needs.
        '';
      };

      callerIf = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          When set, adds an `if:` condition to the caller job in the main workflow.
          Use this to skip dispatch entirely when there are no relevant changes.
          Example: "''${{ fromJSON(needs.changes.outputs.changes)['my-key'] == true }}"
        '';
      };
    };
  };
}
