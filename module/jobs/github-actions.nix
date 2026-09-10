{ lib, config, ... }:

let
  inherit (config.github-actions)
    changesFetchDepth
    checkoutAction
    transformJobName
    forceRunAll
    ;
  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  inherit (config.github-actions.changes) extraPaths;

  jobDerivedPaths = lib.pipe enabledJobs [
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
  ];

  changes = lib.pipe (jobDerivedPaths // lib.filterAttrs (_: paths: paths != [ ]) extraPaths) [
    (builtins.mapAttrs (_: builtins.concatStringsSep "|"))
    (lib.mapAttrsToList (name: paths: "${transformJobName name}:${paths}"))
  ];

  summaryJobCfg = config.github-actions.summaryJob;

  summaryJobNeeds =
    (lib.optional (changes != [ ]) "changes") ++ (map transformJobName (lib.attrNames enabledJobs));

  effectiveSummaryRunsOn =
    if summaryJobCfg.runsOn != null then summaryJobCfg.runsOn else config.github-actions.defaultRunsOn;
in
{
  github-actions.settings = lib.mkMerge [
    {
      jobs = lib.mkMerge [
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
                env = lib.mergeAttrsList [
                  {
                    DIFF_PATHS = builtins.concatStringsSep "\n" changes;
                    GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                    GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
                  }
                  (lib.optionalAttrs forceRunAll.enable {
                    FORCE_RUN_ALL = "\${{ inputs.${forceRunAll.inputName} }}";
                  })
                ];
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

        (lib.mkIf summaryJobCfg.enable {
          ${summaryJobCfg.name} = lib.mergeAttrsList [
            {
              "if" = "\${{ always() }}";
              needs = summaryJobNeeds;
              permissions.actions = "read";
              steps = [
                {
                  shell = "bash";
                  env = {
                    GH_TOKEN = "\${{ github.token }}";
                    SUMMARY_JOB_NAME = summaryJobCfg.name;
                  };
                  run = builtins.readFile ../../packages/gha-job-summary/main.bash;
                }
              ];
            }
            (lib.optionalAttrs (effectiveSummaryRunsOn != null) {
              runs-on = effectiveSummaryRunsOn;
            })
          ];
        })
      ];
    }

    (lib.mkIf (changes != [ ] && forceRunAll.enable) {
      on.workflow_dispatch.inputs.${forceRunAll.inputName} = {
        type = "boolean";
        default = false;
        description = "Skip change detection and run all jobs";
      };
    })
  ];
}
