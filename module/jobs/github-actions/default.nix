{ lib, config, ... }:

let
  inherit (config.pipeline.github-actions) checkoutAction;
  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  changes = lib.pipe enabledJobs [
    (builtins.mapAttrs (_: job: job.branches.default.changes.paths or [ ]))
    (lib.filterAttrs (_: paths: paths != [ ]))
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
          { uses = checkoutAction; }
          {
            id = "diff";
            shell = "bash";
            env = {
              DIFF_PATHS = builtins.concatStringsSep "\n" changes;
              GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
              GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
            };
            run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
          }
        ];
      };
    })

    (lib.mapAttrs' (name: job: {
      name = config.pipeline.github-actions.transformJobName name;
      value = builtins.removeAttrs job.github-actions [ "enable" ];
    }) enabledJobs)
  ];
}
