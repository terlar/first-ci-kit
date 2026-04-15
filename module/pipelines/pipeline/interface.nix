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
