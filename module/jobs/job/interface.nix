{
  lib,
  ci-lib,
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
      path = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Destination path for the downloaded artifact. Defaults to the workspace root when null.";
        example = ".ci/terraform";
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

    runAlways = lib.mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether the job should run regardless of dependency failure.
        Equivalent to GitLab CI's `when: always`.
        On GitHub Actions, adds `always()` to the `if` condition and guards
        required needs with `(result == 'success' || result == 'failure')` to
        avoid running when dependencies were skipped or canceled (e.g. on pull requests).
      '';
    };

    tags = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Tags associated with the job.";
      example = lib.literalExpression ''[ "gke-runner" ]'';
    };

    needs = lib.mkOption {
      type = types.listOf ci-lib.types.needsType;
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

    fetchDepth = lib.mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Number of commits to fetch during clone/checkout. `null` omits the
        setting, relying on the backend default (GitHub Actions: 1,
        GitLab CI: project-level Git shallow clone setting, typically 20).
        Set to `0` for a full clone with complete history.
      '';
      example = 0;
    };

    commands = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Commands to be executed by the job.";
      example = lib.literalExpression ''[ "make build" "make test" ]'';
    };

    env = lib.mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = ''
        Environment variables set for all backends. Merged into GitHub Actions
        job-level `env:` and GitLab CI `variables:`. Backend-specific settings
        (`github-actions.env` and `gitlab-ci.variables`) take precedence.
      '';
      example = lib.literalExpression ''
        {
          LOG_LEVEL = "debug";
          CONFIG_FILE = "config.json";
        }
      '';
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

    pipelineCallProfile = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Name of a profile declared in `config.pipelineCallProfiles`. When set,
        populates `pipelineCall` from the named profile using `lib.mkDefault`, so
        any explicitly set `pipelineCall` options take precedence over the profile.
      '';
    };

    pipelineCall = lib.mkOption {
      type = types.nullOr (
        types.submoduleWith {
          modules = [
            (import ../../pipeline-call-profiles/module.nix)
            { config.gitlab-ci.toChildJobName = lib.mkDefault (childJobSuffix: "${name}_${childJobSuffix}"); }
          ];
        }
      );
      default = null;
      description = "Call a child pipeline (reusable workflow / template include) instead of running commands directly.";
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
