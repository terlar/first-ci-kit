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

    inputs = lib.mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ ./input.nix ];
          shorthandOnlyDefinesConfig = true;
        }
      );
      default = { };
      description = ''
        Declared inputs for this pipeline.
        Becomes on.workflow_call.inputs on GitHub Actions and spec.inputs on GitLab CI.
      '';
    };

    outputs = lib.mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ ./output.nix ];
          shorthandOnlyDefinesConfig = true;
        }
      );
      default = { };
      description = ''
        Declared outputs for this pipeline.
        Becomes on.workflow_call.outputs on GitHub Actions.
      '';
    };

    gitlab-ci.image = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Image for the generate job. Resolved via imageRegistry if a known key,
        otherwise used as a literal image reference.
      '';
    };

    gitlab-ci.dispatch = {
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

    github-actions.dispatch = {
      callerIf = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "If condition on the caller job in ci.yaml.";
      };
    };
  };
}
