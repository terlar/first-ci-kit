{
  lib,
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

        file = lib.mkOption {
          internal = true;
          type = types.package;
          default = lib.pipe config.pipeline.gitlab-ci.settings [
            builtins.toJSON
            (builtins.toFile "pipeline.yml")
          ];
          description = "Package of the pipeline.yml";
        };
      };

      process-compose = {
        settings = lib.mkOption {
          type = types.deferredModule;
          default = { };
          description = "Configuration of process-compose to be passed to process-compose-flake settings.";
        };
      };
    };
  };
}
