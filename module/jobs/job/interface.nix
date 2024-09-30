{ lib, pkgs, ... }:

let
  inherit (lib) types;

  yamlFormat = pkgs.formats.yaml { };

  branchType = types.submoduleWith {
    description = "Job branch configuration";
    modules = [
      {
        options = {
          triggers = {
            onPush = lib.mkEnableOption "trigger on push to branch";
            onMergeRequest = lib.mkEnableOption "trigger on merge request to branch";
          };

          changes = {
            paths = lib.mkOption {
              type = types.listOf types.str;
              default = [ ];
              apply = lib.unique;
              description = "Paths affecting the job.";
            };
          };
        };
      }
    ];
  };

  needsType = types.submoduleWith {
    description = "Job needs configuration";
    modules = [
      {
        options = {
          job = lib.mkOption {
            type = types.str;
            description = "Name of the needed job.";
          };

          optional = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Whether need is optional.";
          };

          artifacts = lib.mkOption {
            type = types.bool;
            default = true;
            description = "Whether artifacts from dependency is used.";
          };
        };
      }
    ];
  };
in
{
  options = {
    needs = lib.mkOption {
      type = types.listOf needsType;
      default = [ ];
      description = "Jobs needed by the job.";
    };

    branches = lib.mkOption {
      type = types.attrsOf branchType;
      default = { };
      description = "Branch configuration for job.";
    };

    image = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Image to use for job.";
    };

    gitlab-ci = lib.mkOption {
      inherit (yamlFormat) type;
      default = { };
      description = "Job configuration targeting GitLab CI.";
    };
  };
}
