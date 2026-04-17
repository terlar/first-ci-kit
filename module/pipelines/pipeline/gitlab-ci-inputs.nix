{ lib, config, ... }:

let
  renderGitlabInput =
    _name: input:
    lib.optionalAttrs (input.default != null) { inherit (input) default; }
    // lib.optionalAttrs (input.description != "") { inherit (input) description; }
    // lib.optionalAttrs (input.type == "boolean") { type = "boolean"; }
    // lib.optionalAttrs (input.type == "choice" && input.options != [ ]) { inherit (input) options; };
in
{
  config = lib.mkIf (config.inputs != { }) {
    gitlab-ci.inputs = lib.mapAttrs renderGitlabInput config.inputs;
  };
}
