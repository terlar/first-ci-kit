{ lib, config, ... }:

let
  inherit (config.github-actions) changesFetchDepth checkoutAction transformJobName;
  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  changes = lib.pipe enabledJobs [
    (builtins.mapAttrs (
      _: job:
      let
        jobPaths = lib.pipe job.branches [
          builtins.attrValues
          (lib.concatMap (b: b.changes.paths))
          lib.unique
        ];
        pathsFromTriggers = lib.pipe (job.triggers or [ ]) [
          (builtins.filter (t: enabledJobs ? ${t}))
          (map (t: lib.concatMap (b: b.changes.paths) (builtins.attrValues enabledJobs.${t}.branches)))
          builtins.concatLists
          lib.unique
        ];
      in
      lib.unique (jobPaths ++ (if jobPaths != [ ] then pathsFromTriggers else [ ]))
    ))
    (lib.filterAttrs (_: paths: paths != [ ]))
    (builtins.mapAttrs (_: builtins.concatStringsSep "|"))
    (lib.mapAttrsToList (name: paths: "${transformJobName name}:${paths}"))
  ];
in
{
  github-actions.settings.jobs = lib.mkMerge [
    (lib.mkIf (changes != [ ]) {
      changes = {
        outputs.changes = "\${{ steps.diff.outputs.changes }}";
        runs-on = config.github-actions.defaultRunsOn;
        steps = [
          {
            uses = checkoutAction;
            "with"."fetch-depth" = changesFetchDepth;
          }
          {
            id = "diff";
            shell = "bash";
            env = {
              DIFF_PATHS = builtins.concatStringsSep "\n" changes;
              GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
              GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
            };
            run = builtins.readFile ../../packages/gha-path-changes/main.bash;
          }
        ];
      };
    })

    (lib.mapAttrs' (name: job: {
      name = config.github-actions.transformJobName name;
      value = builtins.removeAttrs job.github-actions (
        [ "enable" ]
        ++ lib.optionals (job.github-actions.uses or null != null) [
          "runs-on"
          "steps"
        ]
      );
    }) enabledJobs)
  ];
}
