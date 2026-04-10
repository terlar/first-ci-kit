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
              example = lib.literalExpression ''[ "src/" "go.sum" ]'';
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

  artifactUploadType = types.submodule {
    options = {
      name = lib.mkOption {
        type = types.str;
        description = "Artifact name.";
        example = "build-output";
      };
      paths = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "Paths to include in the artifact.";
        example = lib.literalExpression ''[ "dist/" "result.log" ]'';
      };
      retentionDays = lib.mkOption {
        type = types.nullOr types.int;
        default = null;
        description = "Artifact retention in days. Used by both GitHub Actions and GitLab CI (as expire_in), unless overridden by gitlab-ci.expire_in.";
        example = 7;
      };
      gitlab-ci = lib.mkOption {
        type = types.submodule {
          options = {
            expire_in = lib.mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "GitLab CI artifact expiry string. Overrides retentionDays for GitLab CI when set.";
              example = "1 week";
            };
            reports = lib.mkOption {
              type = types.nullOr (types.attrsOf types.str);
              default = null;
              description = "GitLab CI report artifacts.";
              example = lib.literalExpression ''{ terraform = ".ci/terraform/plan-summary.json"; }'';
            };
          };
        };
        default = { };
        description = "GitLab CI-specific artifact upload options.";
      };
    };
  };

  artifactDownloadType = types.submodule {
    options = {
      name = lib.mkOption {
        type = types.str;
        description = "Name of the artifact to download.";
        example = "build-output";
      };
    };
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
      example = lib.literalExpression ''[ "gke-runner" ]'';
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
      example = lib.literalExpression ''
        [
          { job = "build"; }
          { jobSet = "integration"; optional = true; }
        ]
      '';
    };

    triggers = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Jobs triggering the job.";
      example = lib.literalExpression ''[ "deploy" ]'';
    };

    branches = lib.mkOption {
      type = types.attrsOf branchType;
      default = { };
      description = "Branch configuration for job.";
      example = lib.literalExpression ''
        {
          main.triggers.onPush = true;
          main.changes.paths = [ "src/" ];
        }
      '';
    };

    image = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Image to use for job.";
      example = "ubuntu:24.04";
    };

    checkout = (lib.mkEnableOption "whether a git checkout should be made") // {
      default = true;
    };

    commands = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Commands to be executed by the job.";
      example = lib.literalExpression ''[ "make build" "make test" ]'';
    };

    artifacts = lib.mkOption {
      type = types.submodule {
        options = {
          upload = lib.mkOption {
            type = types.nullOr artifactUploadType;
            default = null;
            description = "Artifact to upload after this job completes.";
          };

          download = lib.mkOption {
            type = types.nullOr artifactDownloadType;
            default = null;
            description = "Artifact to download before this job runs.";
          };
        };
      };
      default = { };
      description = "Artifact configuration for this job.";
      example = lib.literalExpression ''
        {
          upload = { name = "build-output"; paths = [ "dist/" ]; };
          download = { name = "build-output"; };
        }
      '';
    };

    github-actions = lib.mkOption {
      type = types.submoduleWith {
        modules = [
          {
            options = {
              enable = lib.mkOption {
                type = types.bool;
                default = true;
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
                default = true;
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
                default = true;
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
