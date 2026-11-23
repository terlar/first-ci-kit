{ config, lib, ... }:

{
  options.first-ci-kit = lib.mkOption {
    type = lib.types.submoduleWith { modules = [ ./module/top-level ]; };
    default = { };
    description = "first-ci-kit configuration.";
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

      # Union of github-actions.actionFiles over every generated top-level
      # pipeline and its children, keyed by action name. Two pipelines that
      # produce the same action name with different content is an error.
      actionEntries =
        lib.concatMap
          (
            pipeline: lib.mapAttrsToList (name: value: { inherit name value; }) pipeline.github-actions.actions
          )
          (
            lib.concatMap (p: [ p ] ++ lib.attrValues p.pipelines) (
              lib.attrValues (lib.filterAttrs (_: p: p.github-actions.generate) config.first-ci-kit.pipelines)
            )
          );
      actionsUnion = lib.foldl' (
        acc: entry:
        if acc ? ${entry.name} && builtins.toJSON acc.${entry.name} != builtins.toJSON entry.value then
          throw "first-ci-kit: action ${entry.name} differs between pipelines"
        else
          acc // { ${entry.name} = entry.value; }
      ) { } actionEntries;
      actionFiles = lib.mapAttrsToList (name: value: {
        name = "actions/${name}/action.yml";
        path = builtins.toFile "action.yml" (builtins.toJSON value);
      }) actionsUnion;
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
            allPipelineFiles (p: p.github-actions.file) ++ actionFiles
          );
          ci-pipelines-gitlab-ci = pkgs.linkFarm "ci-pipelines-gitlab-ci" (
            allPipelineFiles (p: p.gitlab-ci.file)
          );
        }
      ];
    };
}
