{
  lib,
  config,
  ci-lib,
  ...
}:

let
  inherit (lib) types;

  renderGitlabInput =
    _name: input:
    lib.mergeAttrsList [
      (lib.optionalAttrs (input.default != null) { inherit (input) default; })
      (lib.optionalAttrs (input.description != "") { inherit (input) description; })
      (lib.optionalAttrs (input.type == "boolean") { type = "boolean"; })
      (lib.optionalAttrs (input.type == "choice" && input.options != [ ]) { inherit (input) options; })
    ];
in
{
  options.gitlab-ci = {
    inputs = lib.mkOption {
      type = config.types.yamlType;
      default = { };
      description = ''
        Define inputs for the CI/CD configuration.
        This will be added as a separate YAML document at the top of the {file}`pipeline.yml`.
      '';
      example = lib.literalExpression ''
        {
          website = {};
          user.default = "test-user";
          flags.default = "";
        }
      '';
    };

    settings = lib.mkOption {
      type = config.types.yamlType;
      default = { };
      description = "Configuration written for job to {file}`pipeline.yml`.";
      example = lib.literalExpression ''
        {
          image = "ubuntu";
          stages = [ "validate" "test" "build" "deploy" ];
          default.tags = [ "gke-runner" ];
        }
      '';
    };

    defaultStage = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The default stage to use for jobs";
    };

    transformJobName = lib.mkOption {
      type = types.functionTo types.str;
      default = lib.id;
      description = "A function to transform job names";
    };

    fileDocuments = lib.mkOption {
      internal = true;
      type = types.listOf config.types.yamlType;
      default = [ ];
      description = "Documents to write to the pipeline.yml";
    };

    file = lib.mkOption {
      internal = true;
      type = types.package;
      default = lib.pipe config.gitlab-ci.fileDocuments [
        ci-lib.documentsToYAML
        (builtins.toFile "pipeline.yml")
      ];
      description = "Package of the pipeline.yml";
    };
  };

  config = lib.mkIf (config.inputs != { }) {
    gitlab-ci.inputs = lib.mapAttrs renderGitlabInput config.inputs;
  };
}
