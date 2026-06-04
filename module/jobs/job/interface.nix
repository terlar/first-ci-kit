{
  lib,
  ci-lib,
  name,
  rootConfig,
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

    factoryName = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      internal = true;
      description = ''
        Name of the job factory that generated this job. Set automatically
        by the stacks engine; useful for inspection and testing.
      '';
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
      description = ''
        GitHub Actions-specific job configuration. Accepts any YAML-typed
        field supported by GitHub Actions job syntax (e.g. `runs-on`,
        `environment`, `concurrency`). Merged with the shared job settings;
        backend-specific values take precedence over the shared equivalents.

        Set `enable = false` to exclude this job from GitHub Actions output
        while keeping it active for other backends.
      '';
      example = lib.literalExpression ''
        {
          runs-on = "ubuntu-latest";
          environment = "production";
          concurrency = { group = "deploy-prod"; cancel-in-progress = false; };
        }
      '';
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
      description = ''
        GitLab CI-specific job configuration. Accepts any YAML-typed field
        supported by GitLab CI job syntax (e.g. `variables`, `cache`,
        `interruptible`, `resource_group`). Merged with the shared job
        settings; backend-specific values take precedence.

        Set `enable = false` to exclude this job from GitLab CI output while
        keeping it active for other backends.
      '';
      example = lib.literalExpression ''
        {
          resource_group = "deploy-prod";
          interruptible = false;
          variables.TF_VAR_env = "prod";
        }
      '';
    };

    pipelineCall = lib.mkOption {
      type = types.nullOr (
        types.submoduleWith {
          modules = [
            ./pipeline-call.nix
            { config.gitlab-ci.toChildJobName = lib.mkDefault (childJobSuffix: "${name}_${childJobSuffix}"); }
          ];
        }
      );
      default = null;
      description = ''
        Call a child pipeline instead of running commands directly.
        Generates a reusable workflow call (GitHub Actions) or a
        `trigger:include:` job (GitLab CI).

        When set, `commands` and `script` on the job are ignored.
        The child pipeline must be declared separately (e.g. a pipeline
        whose outputs are included via `gitlab-templates/<name>/template.yml`).
      '';
      example = lib.literalExpression ''
        {
          pipeline = "infra";
          inputs = { service = "api"; environment = "prod"; };
        }
      '';
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

              before_script = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
                description = ''
                  Commands to run before the main `commands` in process-compose.
                  Equivalent to `gitlab-ci.before_script`; use this in
                  `jobDefaults` to set up the environment (e.g. load a Nix
                  dev shell) before every job in a job set.
                '';
                example = lib.literalExpression ''
                  [
                    "nix print-dev-env .#profile-tofu > profile-tofu.sh"
                    ". ./profile-tofu.sh"
                  ]
                '';
              };
            };
            config._module.freeformType = types.anything;
          }
        ];
      };
      default = { };
      description = ''
        process-compose-specific job configuration. Accepts arbitrary
        process-compose fields that are merged into the process definition for
        this job (e.g. `availability`, `readiness_probe`).

        Set `enable = false` to exclude this job from process-compose output
        while keeping it active for other backends.
      '';
      example = lib.literalExpression ''
        {
          availability.restart = "on_failure";
          environment = [ "DEBUG=1" ];
        }
      '';
    };
  };
}
