{
  lib,
  pkgs,
  inputs,
}:

let
  evalPipelines =
    module:
    (inputs.flake-parts.lib.evalFlakeModule { inputs.self = { }; } {
      systems = [ ];
      imports = [ ../../flake-module.nix ];
      first-ci-kit.componentPipelines.service = {
        module = {
          imports = [ module ];
          defaultJobFactory = "noop";
          jobFactories.noop.fn = _: { };
        };
        stackDiscovery = {
          path = ../../module/tests/stacks/fixtures/services;
          stackName = "services";
          deployments.subdirectory = "config";
        };
      };
    }).config.first-ci-kit.pipelines;

  pipelines = evalPipelines { github-actions.settings.name = "x"; };
  withComponentArg = evalPipelines (
    { component, ... }:
    {
      github-actions.settings.name = component;
    }
  );

  checks = [
    (lib.assertMsg (
      lib.attrNames pipelines == [
        "service-a"
        "service-b"
      ]
    ) "pipelines: ${toString (lib.attrNames pipelines)}")
    (lib.assertMsg (
      lib.attrNames pipelines.service-a.stacks.services.components == [ "a" ]
    ) "service-a components")
    (lib.assertMsg (pipelines.service-a.github-actions.settings.name == "x") "module imported")
    (lib.assertMsg (
      withComponentArg.service-b.github-actions.settings.name == "b"
    ) "component module arg")
  ];
in
assert lib.all lib.id checks;
pkgs.runCommand "test-component-pipelines" { } "touch $out"
