{ lib, ... }:

let
  inherit (lib) types;

  needsType = types.submoduleWith {
    description = "Nested pipeline needs configuration";
    modules = [
      {
        options.jobSet = lib.mkOption {
          type = types.str;
          description = "Name of the parent job-set that must complete before dispatching.";
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
      description = "Parent job-sets that must complete before this pipeline is dispatched.";
    };

    tags = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        Runner tags for the generate job (GitLab) or caller job (GHA).
        Defaults to the parent gitlab-ci.settings.default.tags when empty.
      '';
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
  };
}
