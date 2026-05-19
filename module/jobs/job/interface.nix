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

  needsEntryType = types.submodule {
    options = {
      job = lib.mkOption {
        type = types.str;
        description = "Name of the job to depend on.";
      };
      artifacts = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Whether to download artifacts from the job.";
      };
      optional = lib.mkOption {
        type = types.bool;
        default = false;
        description = "Whether the job is optional (does not have to exist).";
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
        required needs with `result != 'skipped'` to avoid running when
        dependencies were never triggered (e.g. on pull requests).
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

    pipelineCall = lib.mkOption {
      type = types.nullOr (
        types.submodule {
          options = {
            pipeline = lib.mkOption {
              type = types.str;
              description = ''
                Name of a pipeline declared in `config.pipelines` to call. On GitHub
                Actions the job is rendered as a `uses:` reusable-workflow caller; on
                GitLab CI the job is suppressed and an `include:` entry pointing to
                the pipeline's `gitlab-ci.templatePath` is emitted instead.
              '';
            };

            inputs = lib.mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = ''
                Input values forwarded to the called pipeline on both GitHub
                Actions (`with:`) and GitLab CI (`inputs:`). Changes-detection
                inputs (`changes`, `changes_key`) are injected automatically on
                GitHub Actions when the job has
                `branches.default.changes.paths` configured.
              '';
            };

            github-actions.extraInputs = lib.mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = ''
                Additional GitHub Actions `with:` inputs that are NOT forwarded
                to the GitLab CI include. Use this for GHA-only inputs such as
                `profile` (Nix dev-shell selector) or a dynamic `run_deploy`
                expression.
              '';
            };

            github-actions.passSecrets = lib.mkOption {
              type = types.bool;
              default = true;
              description = ''
                Whether to pass `secrets: inherit` to the called reusable
                workflow. Set to `false` to opt out, e.g. when calling a
                public or cross-org workflow that does not accept inherited
                secrets.
              '';
            };

            gitlab-ci = {
              extraInputs = lib.mkOption {
                type = types.attrsOf (
                  types.either types.str (types.listOf (types.either types.str needsEntryType))
                );
                default = { };
                description = ''
                  Additional GitLab CI `inputs:` values that are NOT forwarded to
                  GitHub Actions. Use this for GitLab CI-only inputs such as
                  `plan_needs` (an array of job names or needs-entry objects with
                  `job`, `artifacts`, and `optional` keys).
                '';
              };

              rulesInput = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  When set to an input name (e.g. `"rules"`), automatically
                  computes all GitLab CI rules (MR + push) from the job's
                  `branches` config and passes them as that input to the child
                  pipeline. The computed value is merged after `extraInputs`.
                '';
              };

              pushRulesInput = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  When set to an input name (e.g. `"deploy_rules"`), automatically
                  computes push-only GitLab CI rules from the job's `branches`
                  config and passes them as that input to the child pipeline.
                  The computed value is merged after `extraInputs`.
                '';
              };

              allRulesInput = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  When set to an input name, automatically computes all GitLab CI
                  rules (MR + push) from the job's `branches` config and passes
                  them as that input to the child pipeline. Unlike `rulesInput`,
                  this can be set alongside `rulesInput` to populate a second
                  input with the same rule set — useful when both plan and deploy
                  inputs need full (MR + push) rules, e.g. for branch-deploy
                  environments. The computed value is merged after `extraInputs`.
                '';
              };

              needsInputs = lib.mkOption {
                type = types.attrsOf types.str;
                default = { };
                description = ''
                  Maps GitLab CI input names to child job name suffixes. For each
                  entry, automatically computes the child job names for all
                  dependency pipelineCall jobs (derived from this job's `needs`,
                  which are populated by jobSet integration) and passes them as
                  that input to the child pipeline. The full child job name for
                  each dependency is produced by calling that dependency's
                  `pipelineCall.gitlab-ci.toChildJobName` with the given suffix.
                  The computed values are merged after `extraInputs`.
                  Example: `{ "plan_needs" = "deploy"; }`
                '';
              };

              toChildJobName = lib.mkOption {
                type = types.functionTo types.str;
                default = childJobSuffix: "${name}_${childJobSuffix}";
                defaultText = lib.literalExpression ''"childJobSuffix: \"''${name}_''${childJobSuffix}\""'';
                description = ''
                  Function from a child job name suffix (e.g. `"deploy"`) to the
                  full child job name as it appears in the parent GitLab CI
                  pipeline (e.g. `"networking_vpc_dev_deploy"`). Used by
                  dependent jobs' `needsInputs` to compute the actual job names
                  to pass as inputs.

                  This encodes the same separator/naming convention as the child
                  pipeline's `gitlab-ci.transformJobName`, but cannot simply
                  delegate to it: when the child pipeline is a GitLab CI
                  component (`asComponent = true`), `transformJobName` contains
                  `$[[ inputs.X ]]` expressions that are only resolved at GitLab
                  CI runtime, not at Nix evaluation time. The default therefore
                  reconstructs the name using the parent job key as prefix with
                  an underscore separator, which is correct whenever the parent
                  job key encodes the same information as the component inputs
                  (the common convention). Override when a different separator is
                  used, e.g.
                  `childJobSuffix: "''${name}:''${childJobSuffix}"` when
                  `transformJobName` uses colons.
                '';
              };

              templatePath = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Local path to the GitLab CI component template for the called
                  pipeline (e.g. "ci/gitlab-templates/profile-terraform/template.yml").
                  When set, takes precedence over looking up the path via
                  `config.pipelines.<pipeline>.gitlab-ci.templatePath`.
                '';
              };
            };
          };
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
