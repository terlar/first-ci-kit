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
    # Jobs sharing a changesKey share one entry with their paths merged.
    (lib.mapAttrsToList (
      name: paths: { ${transformJobName (config.jobs.${name}.changesKey or name)} = paths; }
    ))
    (lib.zipAttrsWith (
      _: paths:
      lib.pipe paths [
        lib.flatten
        lib.unique
        (lib.concatStringsSep "|")
      ]
    ))
    (lib.mapAttrsToList (name: paths: "${name}:${paths}"))
  ];

  resolveBranchKey = key: if key == "default" then config.github-actions.defaultBranch else key;

  onDemandBranches = lib.pipe enabledJobs [
    builtins.attrValues
    (lib.concatMap (job: lib.attrNames (lib.filterAttrs (_: b: b.triggers.onDemand) job.branches)))
    (map resolveBranchKey)
    lib.unique
  ];

  onDemandBaseRefAssertion =
    assert lib.assertMsg (lib.length onDemandBranches <= 1)
      "triggers.onDemand is only supported with a single distinct diff-base branch across all jobs in a pipeline (got: ${toString onDemandBranches})";
    onDemandBranches;

  summaryJobCfg = config.github-actions.summaryJob;

  changesActionName = "first-ci-kit-changes";
  nativeChanges = config.github-actions.changes.mode == "native";
  diffScript = builtins.readFile ../../packages/gha-path-changes/main.bash;

  # Inputs of the diff step; the expanded step gets them as env, the native
  # step passes them to the composite action.
  diffInputs = lib.mergeAttrsList [
    { paths = builtins.concatStringsSep "\n" changes; }
    (lib.optionalAttrs forceRunAll.enable {
      force-run-all = "\${{ inputs.${forceRunAll.inputName} }}";
    })
    (lib.optionalAttrs (onDemandBaseRefAssertion != [ ]) {
      on-demand-base-ref = builtins.head onDemandBaseRefAssertion;
    })
  ];

  diffEnv =
    inputs:
    {
      DIFF_PATHS = inputs.paths;
      GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
      GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
    }
    // lib.optionalAttrs (inputs ? force-run-all) { FORCE_RUN_ALL = inputs.force-run-all; }
    // lib.optionalAttrs (inputs ? on-demand-base-ref) {
      ON_DEMAND_BASE_REF = inputs.on-demand-base-ref;
    };

  diffStep =
    if nativeChanges then
      {
        id = "diff";
        uses = "./.github/actions/${changesActionName}";
        "with" = diffInputs;
      }
    else
      {
        id = "diff";
        shell = "bash";
        env = diffEnv diffInputs;
        run = diffScript;
      };

  # Identical for every pipeline (pipeline specifics are inputs), so pipelines
  # can share one action file.
  changesAction = {
    name = changesActionName;
    description = "Detect which first-ci-kit change groups have changed paths.";
    inputs = {
      paths = {
        description = "Newline-separated `<group>:<glob>|<glob>` entries.";
        required = true;
      };
      force-run-all = {
        description = "Mark every group changed when `true`.";
        required = false;
        default = "";
      };
      on-demand-base-ref = {
        description = "Branch to diff against on workflow_dispatch and schedule events.";
        required = false;
        default = "";
      };
    };
    outputs.changes = {
      description = "JSON object of group name to changed boolean.";
      value = "\${{ steps.diff.outputs.changes }}";
    };
    runs = {
      using = "composite";
      steps = [
        {
          id = "diff";
          shell = "bash";
          env = diffEnv (lib.mapAttrs (n: _: "\${{ inputs.${n} }}") changesAction.inputs);
          run = diffScript;
        }
      ];
    };
  };

  summaryJobNeeds =
    (lib.optional (changes != [ ]) "changes") ++ (map transformJobName (lib.attrNames enabledJobs));

  effectiveSummaryRunsOn = lib.defaultTo config.github-actions.defaultRunsOn summaryJobCfg.runsOn;
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
              diffStep
            ];
          };
        })

        (lib.mapAttrs' (name: job: {
          name = config.github-actions.transformJobName name;
          value = builtins.removeAttrs job.github-actions (
            [
              "enable"
              "conditions"
            ]
            ++ lib.optional (job.github-actions."if" == null) "if"
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

  github-actions.actions = lib.mkIf (nativeChanges && changes != [ ]) {
    ${changesActionName} = changesAction;
  };
}
