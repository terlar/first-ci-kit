{ lib, rootConfig, ... }:

let
  inherit (lib) types;

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
    enable = (lib.mkEnableOption "Job") // {
      default = true;
    };

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

    checkout = (lib.mkEnableOption "whether a git checkout should be made") // {
      default = true;
    };

    commands = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Commands to be executed by the job.";
    };

    github-actions = lib.mkOption {
      type = rootConfig.types.yamlType;
      default = { };
      description = "Job configuration targeting GitHub Actions.";
    };

    gitlab-ci = lib.mkOption {
      type = rootConfig.types.yamlType;
      default = { };
      description = "Job configuration targeting GitLab CI.";
    };
  };
}
