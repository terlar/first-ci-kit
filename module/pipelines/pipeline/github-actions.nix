{ lib, config, ... }:
let
  renderInput =
    _name: input:
    { inherit (input) type; }
    // lib.optionalAttrs input.required { required = true; }
    // lib.optionalAttrs (input.default != null) { inherit (input) default; }
    // lib.optionalAttrs (input.description != "") { inherit (input) description; }
    // lib.optionalAttrs (input.options != [ ]) { inherit (input) options; };

  renderOutput =
    _name: output:
    { inherit (output) value; }
    // lib.optionalAttrs (output.description != "") { inherit (output) description; };

  workflowCall =
    { }
    // lib.optionalAttrs (config.inputs != { }) { inputs = lib.mapAttrs renderInput config.inputs; }
    // lib.optionalAttrs (config.outputs != { }) { outputs = lib.mapAttrs renderOutput config.outputs; };
in
{
  config = lib.mkIf (workflowCall != { }) {
    github-actions.settings.on.workflow_call = workflowCall;
  };
}
