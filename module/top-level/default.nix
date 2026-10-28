{ lib, config, ... }:

let
  topConfig = config;
  ci-lib = import ../lib { inherit lib; };
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

  config.pipelines = lib.mkMerge (
    lib.mapAttrsToList (
      prefix: cp:
      let
        sd = cp.stackDiscovery;
      in
      if (sd.stackName or null) == null then
        throw "first-ci-kit.componentPipelines.${prefix}: stackDiscovery.stackName must be set"
      else
        lib.listToAttrs (
          map (
            c:
            lib.nameValuePair (cp.name c) (_: {
              imports = [ cp.module ];
              _module.args.component = c;
              stackDiscovery = {
                enable = true;
                includeComponents = [ c ];
              }
              // sd;
            })
          ) (ci-lib.discoverComponentNames sd)
        )
    ) config.componentPipelines
  );
}
