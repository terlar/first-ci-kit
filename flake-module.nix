{ config, lib, ... }:

let
  inherit (lib) types;
in
{
  options = {
    first-ci-kit.pipelines = lib.mkOption {
      type = types.lazyAttrsOf (types.submoduleWith { modules = [ ./module ]; });
      default = { };
      description = "Pipelines for CI.";
    };
  };

  config.perSystem.legacyPackages = lib.mkMerge [
    (lib.mapAttrs' (name: value: {
      name = "ci-pipeline-github-actions-${name}";
      value = value.pipeline.github-actions.file;
    }) config.first-ci-kit.pipelines)

    (lib.mapAttrs' (name: value: {
      name = "ci-pipeline-gitlab-ci-${name}";
      value = value.pipeline.gitlab-ci.file;
    }) config.first-ci-kit.pipelines)
  ];
}
