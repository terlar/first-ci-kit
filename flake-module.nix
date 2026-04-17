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
    let
      # Collect all pipeline files (top-level + children) for a given backend getter.
      # Returns a list of { name = "<key>.yml"; path = <drv>; } suitable for linkFarm.
      allPipelineFiles =
        getter:
        lib.mapAttrsToList (name: value: {
          name = "${name}.yml";
          path = getter value;
        }) config.first-ci-kit.pipelines
        ++ lib.concatLists (
          lib.mapAttrsToList (
            parentName: parentValue:
            lib.mapAttrsToList (childName: childValue: {
              name = "${parentName}-${childName}.yml";
              path = getter childValue;
            }) parentValue.pipelines
          ) config.first-ci-kit.pipelines
        );
    in
    {
      packages.gha-path-changes = pkgs.callPackage ./packages/gha-path-changes { };

      legacyPackages = lib.mkMerge [
        (lib.mapAttrs' (name: value: {
          name = "ci-pipeline-github-actions-${name}";
          value = value.github-actions.file;
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
            ]
          ) config.first-ci-kit.pipelines
        ))

        # Bundle packages: one derivation per backend containing all pipeline files.
        # Used by git hooks to avoid N separate nix build invocations (one eval each).
        {
          ci-pipelines-github-actions = pkgs.linkFarm "ci-pipelines-github-actions" (
            allPipelineFiles (p: p.github-actions.file)
          );
          ci-pipelines-gitlab-ci = pkgs.linkFarm "ci-pipelines-gitlab-ci" (
            allPipelineFiles (p: p.gitlab-ci.file)
          );
        }
      ];
    };
}
