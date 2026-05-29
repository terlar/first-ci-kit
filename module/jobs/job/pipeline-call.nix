{ lib, ... }:

let
  inherit (lib) types;

  gitlabNeedsEntryType = types.submoduleWith {
    description = "GitLab CI needs entry";
    modules = [
      {
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
            description = "Whether the job is optional.";
          };
        };
      }
    ];
  };
in
{
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
        Input values forwarded to the called pipeline on both GitHub Actions
        (`with:`) and GitLab CI (`inputs:`). Changes-detection inputs
        (`changes`, `changes_key`) are injected automatically on GitHub
        Actions when the job has `branches.default.changes.paths` configured.
      '';
    };

    github-actions = {
      extraInputs = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Additional GitHub Actions `with:` inputs that are NOT forwarded to
          the GitLab CI include. Use this for GHA-only inputs such as
          `profile` (Nix dev-shell selector) or a dynamic `run_deploy`
          expression.
        '';
      };

      passSecrets = lib.mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to pass `secrets: inherit` to the called reusable workflow.
          Set to `false` to opt out, e.g. when calling a public or cross-org
          workflow that does not accept inherited secrets.
        '';
      };
    };

    gitlab-ci = {
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

      rulesInput = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          When set to an input name (e.g. `"rules"`), automatically computes
          all GitLab CI rules (MR + push) from the job's `branches` config and
          passes them as that input to the child pipeline. The computed value
          is merged after `extraInputs`.
        '';
      };

      pushRulesInput = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          When set to an input name (e.g. `"deploy_rules"`), automatically
          computes push-only GitLab CI rules from the job's `branches` config
          and passes them as that input to the child pipeline. The computed
          value is merged after `extraInputs`.
        '';
      };

      allRulesInput = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          When set to an input name, automatically computes all GitLab CI
          rules (MR + push) from the job's `branches` config and passes them
          as that input to the child pipeline. Unlike `rulesInput`, this can
          be set alongside `rulesInput` to populate a second input with the
          same rule set. The computed value is merged after `extraInputs`.
        '';
      };

      needsInputs = lib.mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = ''
          Maps GitLab CI input names to child job name suffixes. For each
          entry, automatically computes the child job names for all dependency
          pipelineCall jobs and passes them as needs-entry objects
          (`{ job, optional = true, artifacts = false }`) as that input to the
          child pipeline. The computed values are merged after `extraInputs`.
          Example: `{ "plan_needs" = "deploy"; }`
        '';
      };

      extraInputs = lib.mkOption {
        type = types.attrsOf (
          types.either types.str (types.listOf (types.either types.str gitlabNeedsEntryType))
        );
        default = { };
        description = ''
          Additional GitLab CI `inputs:` values that are NOT forwarded to
          GitHub Actions. Use this for GitLab CI-only inputs such as
          `plan_needs` (an array of job names or needs-entry objects with
          `job`, `artifacts`, and `optional` keys).
        '';
      };

      toChildJobName = lib.mkOption {
        type = types.functionTo types.str;
        default = lib.id;
        defaultText = lib.literalExpression "lib.id";
        description = ''
          Function from a child job name suffix (e.g. `"deploy"`) to the full
          child job name as it appears in the parent GitLab CI pipeline (e.g.
          `"networking_vpc_dev_deploy"`). Used by dependent jobs'
          `needsInputs` to compute the actual job names to pass as inputs.

          The default (`lib.id`) is a neutral identity function. Jobs
          override this via `lib.mkDefault` to prefix the parent job key with
          an underscore separator, e.g.
          `childJobSuffix: "''${name}_''${childJobSuffix}"`. Override
          explicitly when a different separator is used, e.g.
          `childJobSuffix: "''${name}:''${childJobSuffix}"` when
          `transformJobName` uses colons.
        '';
      };
    };
  };
}
