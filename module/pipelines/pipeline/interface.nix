{ lib, ci-lib, ... }:

let
  inherit (lib) types;
in
{
  options = {
    needs = lib.mkOption {
      type = types.listOf ci-lib.types.needsType;
      default = [ ];
      description = "Parent jobs or job-sets that must complete before this pipeline is dispatched.";
    };

    gitlab-ci = {
      templatePath = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Local path to the GitLab CI component template for this pipeline (e.g.
          "ci/gitlab-templates/profile-terraform/template.yml"). When set, jobs
          that call this pipeline via `pipelineCall` will emit an `include:` entry
          pointing to this path instead of a trigger job.
        '';
      };

      asComponent = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          When true, no generate-X/trigger-X dispatch jobs are created in the
          parent pipeline for this child. The component YAML is still rendered
          normally via gitlab-ci.file.
        '';
      };
      image = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Image for the generate job. Resolved via imageRegistry if a known key,
          otherwise used as a literal image reference.
        '';
      };

      dispatch = {
        generateJob = {
          beforeScript = lib.mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Extra before_script lines for the generate job.";
          };

          extraRules = lib.mkOption {
            type = types.listOf (types.attrsOf types.anything);
            default = [ ];
            description = "Extra rules prepended to the generate job's rules list.";
          };

          extraArtifactPaths = lib.mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Extra artifact paths included in the generate job, in addition to the generated yml file.";
          };
        };

        trigger = {
          strategy = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "trigger.strategy value (e.g. 'depend'). Null = fire-and-forget.";
          };

          forward = lib.mkOption {
            type = types.nullOr (types.attrsOf types.bool);
            default = null;
            description = "trigger.forward configuration (e.g. { pipeline_variables = true; }).";
          };
        };
      };
    };

    github-actions.dispatch = {
      callerIf = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "If condition on the caller job in ci.yaml.";
      };
    };
  };
}
