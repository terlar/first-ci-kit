{
  lib,
  ci-lib,
  config,
  ...
}:

let
  inherit (lib) types;
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

    pipeline = {
      github-actions = {
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
          default = "actions/upload-artifact@v4";
          description = "The upload-artifact action to use for artifact upload steps";
          example = "actions/upload-artifact@v3";
        };

        downloadArtifactAction = lib.mkOption {
          type = types.str;
          default = "actions/download-artifact@v4";
          description = "The download-artifact action to use for artifact download steps";
          example = "actions/download-artifact@v3";
        };

        file = lib.mkOption {
          internal = true;
          type = types.package;
          default = lib.pipe config.pipeline.github-actions.settings [
            builtins.toJSON
            (builtins.toFile "workflow.yml")
          ];
          description = "Package of the workflow.yml";
        };
      };

      gitlab-ci = {
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
          default = lib.pipe config.pipeline.gitlab-ci.fileDocuments [
            ci-lib.documentsToYAML
            (builtins.toFile "pipeline.yml")
          ];
          description = "Package of the pipeline.yml";
        };
      };

      process-compose = {
        cli = lib.mkOption {
          type = types.raw;
          default = { };
          description = "CLI configuration of process-compose to be passed to process-compose-flake cli.";
        };

        settings = lib.mkOption {
          type = types.deferredModule;
          default = { };
          description = "Configuration of process-compose to be passed to process-compose-flake settings.";
        };
      };
    };
  };
}
