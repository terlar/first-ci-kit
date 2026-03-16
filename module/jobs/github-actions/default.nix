{ lib, config, ... }:

let
  enabledJobs = lib.filterAttrs (_: builtins.getAttr "enable") config.jobs;

  changesPathsAttrPath = [
    "branches"
    "default"
    "changes"
    "paths"
  ];

  changes = lib.pipe enabledJobs [
    (lib.filterAttrs (_: lib.hasAttrByPath changesPathsAttrPath))
    (builtins.mapAttrs (_: lib.getAttrFromPath changesPathsAttrPath))
    (builtins.mapAttrs (_: builtins.concatStringsSep "\\|"))
    (lib.mapAttrsToList (name: paths: "${name}:${paths}"))
  ];
in
{
  pipeline.github-actions.settings.jobs = lib.mkMerge [
    (lib.mkIf (changes != [ ]) {
      changes = {
        outputs.changes = "\${{ steps.diff.outputs.changes }}";
        runs-on = config.pipeline.github-actions.defaultRunsOn;
        steps = [
          {
            id = "diff";
            shell = "bash";
            env.PATHS = builtins.concatStringsSep "\n" changes;
            run = builtins.readFile ./diff-script;
          }
        ];
      };
    })

    (lib.mapAttrs' (name: job: {
      name = config.pipeline.github-actions.transformJobName name;
      value = job.github-actions;
    }) enabledJobs)
  ];
}
