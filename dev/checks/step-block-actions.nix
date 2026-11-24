{
  lib,
  pkgs,
  inputs,
}:

let
  # The github-actions bundle's linkFarm entries for the given pipelines.
  bundleEntries =
    pipelines:
    (inputs.flake-parts.lib.evalFlakeModule { inputs.self = { }; } {
      systems = [ pkgs.stdenv.hostPlatform.system ];
      imports = [ ../../flake-module.nix ];
      perSystem._module.args.pkgs = pkgs;
      first-ci-kit.pipelines = pipelines;
    })
    .config.allSystems.${pkgs.stdenv.hostPlatform.system}.legacyPackages.ci-pipelines-github-actions.passthru.entries;

  nativePipeline = greetRun: {
    github-actions.stepBlocks.mode = "native";
    stepBlocks.greet.steps = _: [ { run = greetRun; } ];
    stepBlocks.unused.steps = _: [ { run = "echo unused"; } ];
    jobs.greet = {
      checkout.enable = true;
      steps = [ { block = "greet"; } ];
    };
  };

  shared = bundleEntries {
    a = nativePipeline "echo hello";
    b = nativePipeline "echo hello";
  };

  conflicting = bundleEntries {
    a = nativePipeline "echo hello";
    b = nativePipeline "echo bye";
  };

  checks = [
    (lib.assertMsg (
      lib.attrNames shared == [
        "a.yml"
        "actions/greet/action.yml"
        "b.yml"
      ]
    ) "bundle: ${toString (lib.attrNames shared)}")
    (lib.assertMsg (
      !(builtins.tryEval (builtins.seq conflicting."actions/greet/action.yml" null)).success
    ) "conflicting action files must fail")
  ];
in
assert lib.all lib.id checks;
pkgs.runCommand "test-step-block-actions" { } "touch $out"
