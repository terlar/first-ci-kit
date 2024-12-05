{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) types;

  yamlFormat = pkgs.formats.yaml { };
in
{
  options = {
    pipeline = {
      github-actions = {
        settings = lib.mkOption {
          inherit (yamlFormat) type;
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
          default = yamlFormat.generate "workflow.yml" config.pipeline.github-actions.settings;
          description = "Package of the workflow.yml";
        };
      };

      gitlab-ci = {
        settings = lib.mkOption {
          inherit (yamlFormat) type;
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
          default = yamlFormat.generate "pipeline.yml" config.pipeline.gitlab-ci.settings;
          description = "Package of the pipeline.yml";
        };
      };
    };
  };
}
