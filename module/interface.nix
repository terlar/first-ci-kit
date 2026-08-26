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
      description = ''
        Named map of container image references. Jobs can reference entries
        here (e.g. `config.imageRegistry.tofu`) instead of hard-coding image
        strings, making registry or version changes a single-point edit.

        When a job image is resolved through this registry, entries without a
        `/` are treated as relative and prefixed with
        {option}`gitlab-ci.images.repository` / {option}`github-actions.images.repository`
        when set; entries containing a `/` are used as-is. Job image references
        that are not registry keys are never prefixed.
      '';
      example = lib.literalExpression ''
        {
          tofu   = "registry.example.com/tofu:1.9";
          python = "registry.example.com/python:3.12";
        }
      '';
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
        Declared inputs for this pipeline. Becomes `on.workflow_call.inputs`
        on GitHub Actions and `spec.inputs` on GitLab CI.

        When `autoEnvInputs = true` (the default), each input is also
        injected as an uppercased environment variable available to all jobs.
      '';
      example = lib.literalExpression ''
        {
          service   = { type = "string"; required = true; description = "Service name to deploy."; };
          dry-run   = { type = "boolean"; default = "false"; description = "Skip destructive steps."; };
          environment = {
            type = "choice";
            options = [ "dev" "stg" "prod" ];
            default = "dev";
          };
        }
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
        Declared outputs for this pipeline. Becomes `on.workflow_call.outputs`
        on GitHub Actions. GitLab CI does not currently support pipeline-level
        outputs.
      '';
      example = lib.literalExpression ''
        {
          plan-summary.value = "''${{ jobs.plan.outputs.summary }}";
        }
      '';
    };

    formatJobName = lib.mkOption {
      type = types.functionTo types.str;
      default = lib.concatStringsSep "_";
      defaultText = lib.literalExpression ''lib.concatStringsSep "_"'';
      description = ''
        Function from a list of name parts to a job name string. Used by the
        stacks module when constructing job and jobSet names, and passed to
        factory functions as `formatJobName` so factories can use the same
        convention.

        Defaults to joining parts with underscores, e.g.
        `["app" "api" "dev"]` → `"app_api_dev"`.
      '';
    };

    autoEnvInputs = lib.mkOption {
      type = types.bool;
      default = true;
      description = ''
        When true and inputs are declared, automatically inject each input as an
        uppercased environment variable available to all jobs.

        GitHub Actions: adds `env:` at workflow level mapping e.g. SERVICE to
        `''${{ inputs.service }}`.

        GitLab CI: adds `variables:` at pipeline level mapping e.g. SERVICE to
        `$[[ inputs.service ]]`.

        Set to false to opt out and manage env/variables manually.
      '';
    };
  };
}
