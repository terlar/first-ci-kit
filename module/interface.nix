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
    pipeline.gitlab-ci = {
      settings = lib.mkOption {
        inherit (yamlFormat) type;
        default = { };
        description = "Configuration written for job to {file}`pipeline.yml`.";
        example = lib.literalExpression ''
          {
            image = "ubuntu";
            stages = ["validate" "test" "build" "deploy"];
            default.tags = ["gke-runner"];
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
}
