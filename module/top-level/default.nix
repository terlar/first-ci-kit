{ lib, config, ... }:

let
  topConfig = config;
in
{
  imports = [ ./interface.nix ];

  options.pipelines = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        modules = [
          (
            { name, config, ... }:
            {
              imports = [ ../. ];
              # Make all top-level pipelines accessible to the job renderer so that
              # pipelineCall can resolve templatePath for sibling (non-child) pipelines.
              _module.args.allPipelines = topConfig.pipelines;
              # Default templatePath follows the convention
              # "<templatesPath>/<name>/template.yml" so that pipelines used as
              # GitLab CI components require no explicit path configuration.
              gitlab-ci.templatePath = lib.mkDefault "${config.gitlab-ci.templatesPath}/${name}/template.yml";
            }
          )
        ];
      }
    );
  };
}
