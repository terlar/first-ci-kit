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
      # Collect top-level pipeline files for a given backend getter.
      # Returns a list of { name = "<key>.yml"; path = <drv>; } suitable for linkFarm.
      # Child pipelines are intentionally excluded: they are dispatch targets built
      # on-demand in CI via mkGitlabDispatchJobs, not generated locally.
      allPipelineFiles =
        getter:
        lib.mapAttrsToList (name: value: {
          name = "${name}.yml";
          path = getter value;
        }) config.first-ci-kit.pipelines;
    in
    {
      packages.gha-path-changes = pkgs.callPackage ./packages/gha-path-changes { };
      packages.gha-job-summary = pkgs.callPackage ./packages/gha-job-summary { };

      legacyPackages = lib.mkMerge [
        # Child pipeline legacyPackages for GitLab CI: ci-pipeline-gitlab-ci-{parent}-{child}
        # Required by mkGitlabDispatchJobs which references these by name in generated nix build commands.
        (lib.mkMerge (
          lib.mapAttrsToList (
            parentName: parentValue:
            lib.mapAttrs' (childName: childValue: {
              name = "ci-pipeline-gitlab-ci-${parentName}-${childName}";
              value = childValue.gitlab-ci.file;
            }) parentValue.pipelines
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
