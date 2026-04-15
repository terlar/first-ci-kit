{ config, lib, ... }:

{
  perSystem.process-compose = lib.mapAttrs' (name: value: {
    name = "pipeline-${name}";
    value = value.process-compose;
  }) config.first-ci-kit.pipelines;
}
