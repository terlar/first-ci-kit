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
    };
  };
}
