{ lib, ... }:

let
  inherit (lib) types;

  inputModule = {
    options = {
      type = lib.mkOption {
        type = lib.types.enum [
          "string"
          "boolean"
          "number"
          "environment"
          "choice"
        ];
        default = "string";
        description = "Input type.";
      };

      required = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether this input is required.";
      };

      default = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Default value. Must be a string (GitHub Actions requirement).";
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description of this input.";
      };

      options = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Valid choices. Only meaningful when type = 'choice'.";
      };
    };
  };

  outputModule = {
    options = {
      value = lib.mkOption {
        type = lib.types.str;
        description = ''
          Expression referencing the job output.
          Example: "''${{ jobs.plan.outputs.plan }}"
        '';
      };

      description = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Human-readable description of this output.";
      };
    };
  };
in
{
  options = {
    imageRegistry = lib.mkOption {
      type = types.lazyAttrsOf types.str;
      default = { };
      description = "Image registry with image names";
    };

    types = lib.mkOption {
      internal = true;
      type = types.lazyAttrsOf types.optionType;
      default = {
        yamlType =
          let
            valueType =
              types.nullOr (
                types.oneOf [
                  types.bool
                  types.int
                  types.float
                  types.str
                  types.path
                  (types.attrsOf valueType)
                  (types.listOf valueType)
                ]
              )
              // {
                description = "YAML value";
              };
          in
          valueType;
      };
    };

    inputs = lib.mkOption {
      type = types.attrsOf (
        types.submoduleWith {
          modules = [ inputModule ];
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
          modules = [ outputModule ];
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
