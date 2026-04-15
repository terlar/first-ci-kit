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

        # Child pipeline legacyPackages: ci-pipeline-{backend}-{parent}-{child}
        (lib.mkMerge (
          lib.mapAttrsToList (
            parentName: parentValue:
            lib.mkMerge [
              (lib.mapAttrs' (childName: childValue: {
                name = "ci-pipeline-gitlab-ci-${parentName}-${childName}";
                value = childValue.gitlab-ci.file;
              }) parentValue.pipelines)
              (lib.mapAttrs' (childName: childValue: {
                name = "ci-pipeline-github-actions-${parentName}-${childName}";
                value = childValue.github-actions.file;
              }) parentValue.pipelines)
              (lib.mapAttrs' (childName: childValue: {
                name = "ci-pipeline-github-actions-${parentName}-${childName}-reusable-workflows";
                value =
                  pkgs.runCommand "reusable-workflows-${parentName}-${childName}"
                    { nativeBuildInputs = [ pkgs.yq-go ]; }
                    ''
                      mkdir -p $out
                      ${lib.concatStrings (
                        lib.mapAttrsToList (jobSetName: file: ''
                          yq --prettyPrint --output-format yaml ${file} > $out/${jobSetName}.yml
                        '') childValue.github-actions.reusableWorkflowFiles
                      )}
                    '';
              }) parentValue.pipelines)
            ]
          ) config.first-ci-kit.pipelines
        ))
      ];
    };
}
