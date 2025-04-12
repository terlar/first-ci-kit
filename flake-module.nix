{ config, lib, ... }:

let
  inherit (lib) mkOption types;
in
{
  options.first-ci-kit.pipelines = mkOption {
    type = types.lazyAttrsOf (types.submoduleWith { modules = [ ./module ]; });
    default = { };
    description = "Pipelines for CI.";
  };

  config.perSystem.packages = lib.mapAttrs' (name: value: {
    name = "ci-pipeline-github-actions-${name}";
    value = value.pipeline.github-actions.file;
  }) config.first-ci-kit.pipelines;
}
