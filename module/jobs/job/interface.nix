{
  lib,
  name,
  rootConfig,
  config,
  ...
}:

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
              apply = lib.unique;
              default = [ ];
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
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job.";
          };

          jobSet = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job set.";
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

  expandNeedJobSet =
    need:
    if need.jobSet == null then
      {
        inherit (need) job optional artifacts;
      }
    else
      map (job: {
        inherit job;
        inherit (need) optional artifacts;
      }) rootConfig.jobSets.${need.jobSet}.jobs;
in
{
  options = {
    enable = (lib.mkEnableOption "Job") // {
      default = true;
    };

    tags = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Tags associated with the job.";
    };

    needs = lib.mkOption {
      type = types.listOf needsType;
      apply =
        v:
        lib.pipe v [
          (map expandNeedJobSet)
          lib.flatten
          lib.unique
          (builtins.filter (need: need.job != name))
        ];
      default = [ ];
      description = "Jobs needed by the job.";
    };

    triggers = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Jobs triggering the job.";
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
      type = types.submoduleWith {
        modules = [
          {
            options = {
              enable = lib.mkOption {
                type = types.bool;
                default = config.enable;
                description = "Whether the job is enabled for GitHub Actions.";
              };
            };
            config._module.freeformType = rootConfig.types.yamlType;
          }
        ];
      };
      default = { };
      description = "Job configuration targeting GitHub Actions.";
    };

    gitlab-ci = lib.mkOption {
      type = types.submoduleWith {
        modules = [
          {
            options = {
              enable = lib.mkOption {
                type = types.bool;
                default = config.enable;
                description = "Whether the job is enabled for GitLab CI.";
              };
            };
            config._module.freeformType = rootConfig.types.yamlType;
          }
        ];
      };
      default = { };
      description = "Job configuration targeting GitLab CI.";
    };

    process-compose = lib.mkOption {
      type = types.submoduleWith {
        modules = [
          {
            options = {
              enable = lib.mkOption {
                type = types.bool;
                default = config.enable;
                description = "Whether the job is enabled for process-compose.";
              };
            };
            config._module.freeformType = types.deferredModule;
          }
        ];
      };
      default = { };
      description = "Job configuration targeting process-compose.";
    };
  };
}
