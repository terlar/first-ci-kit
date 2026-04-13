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

  config.perSystem =
    { pkgs, ... }:
    {
      packages.gha-path-changes = pkgs.callPackage ./packages/gha-path-changes { };

      legacyPackages = lib.mkMerge [
        (lib.mapAttrs' (name: value: {
          name = "ci-pipeline-github-actions-${name}";
          value = value.github-actions.file;
        }) config.first-ci-kit.pipelines)

        (lib.mapAttrs' (name: value: {
          name = "ci-pipeline-github-actions-${name}-reusable-workflows";
          value = pkgs.runCommand "reusable-workflows-${name}" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
            mkdir -p $out
            ${lib.concatStrings (
              lib.mapAttrsToList (jobSetName: file: ''
                yq --prettyPrint --output-format yaml ${file} > $out/${jobSetName}.yml
              '') value.github-actions.reusableWorkflowFiles
            )}
          '';
        }) config.first-ci-kit.pipelines)

        (lib.mapAttrs' (name: value: {
          name = "ci-pipeline-gitlab-ci-${name}";
          value = value.gitlab-ci.file;
        }) config.first-ci-kit.pipelines)
      ];
    };
}
