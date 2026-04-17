{ lib, config, ... }:

let
  inherit (lib) types;

  renderInput =
    _name: input:
    {
      inherit (input) type;
    }
    // lib.optionalAttrs input.required { required = true; }
    // lib.optionalAttrs (input.default != null) { inherit (input) default; }
    // lib.optionalAttrs (input.description != "") { inherit (input) description; }
    // lib.optionalAttrs (input.options != [ ]) { inherit (input) options; };

  renderOutput =
    _name: output:
    {
      inherit (output) value;
    }
    // lib.optionalAttrs (output.description != "") { inherit (output) description; };

  workflowCall =
    { }
    // lib.optionalAttrs (config.inputs != { }) { inputs = lib.mapAttrs renderInput config.inputs; }
    // lib.optionalAttrs (config.outputs != { }) {
      outputs = lib.mapAttrs renderOutput config.outputs;
    };
in
{
  options.github-actions = {
    settings = lib.mkOption {
      type = config.types.yamlType;
      default = { };
      description = "Configuration written for job to {file}`workflow.yml`.";
      example = lib.literalExpression ''
        {
          name = "CI";
          on = [ "push" ];
          env.DAY_OF_WEEK = "Monday";
        }
      '';
    };

    defaultRunsOn = lib.mkOption {
      type = with types; nullOr (either str (listOf str));
      default = null;
      description = "The default runs-on to use for jobs";
    };

    transformJobName = lib.mkOption {
      type = types.functionTo types.str;
      default = lib.id;
      description = "A function to transform job names";
    };

    checkoutAction = lib.mkOption {
      type = types.str;
      default = "actions/checkout@v6";
      description = "The default checkout action to use for jobs";
      example = "actions/checkout@v5";
    };

    uploadArtifactAction = lib.mkOption {
      type = types.str;
      default = "actions/upload-artifact@v7";
      description = "The upload-artifact action to use for artifact upload steps";
      example = "actions/upload-artifact@v3";
    };

    downloadArtifactAction = lib.mkOption {
      type = types.str;
      default = "actions/download-artifact@v8";
      description = "The download-artifact action to use for artifact download steps";
      example = "actions/download-artifact@v3";
    };

    file = lib.mkOption {
      internal = true;
      type = types.package;
      default = lib.pipe config.github-actions.settings [
        builtins.toJSON
        (builtins.toFile "workflow.yml")
      ];
      description = "Package of the workflow.yml";
    };
  };

  config = lib.mkIf (workflowCall != { }) {
    github-actions.settings.on.workflow_call = workflowCall;
  };
}
