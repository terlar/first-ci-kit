{ lib, config, ... }:

let
  inherit (config.pipeline.github-actions) checkoutAction defaultRunsOn transformJobName;
  mkReusableWorkflow = import ./reusable-workflow.nix { inherit lib; };

  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  # Job-sets that opted into reusable workflow generation, with at least one job
  reusableJobSets = lib.filterAttrs (
    _: js: js.github-actions.reusableWorkflow && js.jobs != [ ]
  ) config.jobSets;

  # Job-sets that should generate their own .yml file (reusable, non-empty, NOT redirecting to external file)
  generatingJobSets = lib.filterAttrs (
    _: js:
    js.github-actions.reusableWorkflow
    && js.jobs != [ ]
    && js.github-actions.reusableWorkflowFile == null
  ) config.jobSets;

  # Job-sets that redirect to an external reusable workflow file (reusableWorkflowFile != null)
  # Their jobs' changes.paths must still appear in the outer changes job so that callerIf conditions work.
  redirectingJobSets = lib.filterAttrs (
    _: js:
    js.github-actions.reusableWorkflow
    && js.jobs != [ ]
    && js.github-actions.reusableWorkflowFile != null
  ) config.jobSets;

  # Lookup set of job names belonging to any reusable job-set
  reusableJobNames = lib.genAttrs (lib.pipe reusableJobSets [
    builtins.attrValues
    (builtins.concatMap (js: js.jobs))
  ]) (_: true);

  # Reverse lookup: raw job name → the reusable job-set name that contains it.
  # Used to map individual job names back to their reusable job-set when building
  # caller needs from non-reusable job-set expansions.
  jobNameToReusableJobSet = lib.pipe reusableJobSets [
    (lib.mapAttrsToList (jsName: js: map (jobName: lib.nameValuePair jobName jsName) js.jobs))
    lib.flatten
    builtins.listToAttrs
  ];

  # Jobs NOT in any reusable job-set → render inline in settings.jobs
  inlineEnabledJobs = lib.filterAttrs (name: _: !(reusableJobNames ? ${name})) enabledJobs;

  # Jobs IN a reusable job-set → rendered inside reusable workflow files
  reusableEnabledJobs = lib.filterAttrs (name: _: reusableJobNames ? ${name}) enabledJobs;

  # Build list of "name:paths\\|..." strings for the changes job
  mkChangesEntries =
    jobs:
    lib.pipe jobs [
      (builtins.mapAttrs (_: job: job.branches.default.changes.paths or [ ]))
      (lib.filterAttrs (_: paths: paths != [ ]))
      (builtins.mapAttrs (_: builtins.concatStringsSep "\\|"))
      (lib.mapAttrsToList (name: paths: "${name}:${paths}"))
    ];

  inlineChanges = mkChangesEntries inlineEnabledJobs;

  # Collect changes.paths from all jobs in redirecting job-sets, directly from config.jobs.
  # Jobs in externally-redirected job-sets are not in inlineEnabledJobs, so their paths
  # must be collected separately to populate the outer changes job for callerIf conditions.
  #
  # Key selection: if the job-set has reusableWorkflowInputs.changes_key, use that as the
  # DIFF_PATHS key (so it matches the callerIf condition). Otherwise fall back to the
  # individual job name (backward-compatible behaviour).
  #
  # Path collection: when changes_key is present, collect unique paths across ALL branches
  # of all jobs in the job-set (not just branches.default) so that deployments whose
  # branches.default is empty (e.g. prd-only deployments on a production branch) are
  # still included.
  redirectingChanges =
    let
      # Collect all unique paths across all branches of a single job
      allPathsForJob =
        jobName:
        lib.pipe (config.jobs.${jobName}.branches or { }) [
          builtins.attrValues
          (builtins.concatMap (branch: branch.changes.paths or [ ]))
          lib.unique
        ];

      # Build one entry per redirecting job-set
      entryForJobSet =
        _jsName: js:
        let
          # Use the explicit changes_key if provided, otherwise fall back to per-job entries
          changesKey = js.github-actions.reusableWorkflowInputs.changes_key or null;
        in
        if changesKey != null then
          let
            # Collect all unique paths from every job in this job-set, across all branches
            allPaths = lib.pipe js.jobs [
              (builtins.concatMap allPathsForJob)
              lib.unique
            ];
          in
          lib.optional (allPaths != [ ]) "${changesKey}:${builtins.concatStringsSep "\\|" allPaths}"
        else
          # No changes_key: fall back to per-job entries using job names as keys (branches.default only)
          mkChangesEntries (lib.filterAttrs (name: _: builtins.elem name js.jobs) config.jobs);
    in
    lib.pipe redirectingJobSets [
      (lib.mapAttrsToList entryForJobSet)
      lib.flatten
    ];

  allOuterChanges = inlineChanges ++ redirectingChanges;
  hasOuterChanges = allOuterChanges != [ ];

  # -----------------------------------------------------------------------
  # Caller: one workflow_call job per opted-in job-set
  # -----------------------------------------------------------------------
  callerJobForJobSet =
    jsName: js:
    let
      # For each needed job-set: if it's also reusable, use its name directly.
      # Otherwise expand to individual job names — but each expanded job may itself
      # live inside a reusable workflow, in which case we emit the reusable job-set
      # name rather than the (now-hidden) individual job name.
      callerNeedsFromJobSets = lib.pipe js.needs [
        (builtins.concatMap (
          { jobSet }:
          if reusableJobSets ? ${jobSet} then
            [ (transformJobName jobSet) ]
          else
            map (
              jobName: transformJobName (jobNameToReusableJobSet.${jobName} or jobName)
            ) config.jobSets.${jobSet}.jobs
        ))
      ];

      # Also collect inline job dependencies from individual jobs in this job-set:
      # if a job inside this reusable workflow needs an inline job (not in any
      # reusable job-set), that ordering must be expressed at the caller level.
      callerNeedsFromInlineJobDeps = lib.pipe js.jobs [
        (builtins.concatMap (
          jobName:
          let
            job = config.jobs.${jobName};
          in
          lib.pipe job.needs [
            (builtins.filter (
              need: need.job != null && !(reusableJobNames ? ${need.job}) && (inlineEnabledJobs ? ${need.job})
            ))
            (map (need: transformJobName need.job))
          ]
        ))
      ];

      callerNeeds = lib.unique (
        callerNeedsFromJobSets ++ callerNeedsFromInlineJobDeps ++ js.github-actions.callerExtraNeeds
      );

      usesPath =
        if js.github-actions.reusableWorkflowFile != null then
          js.github-actions.reusableWorkflowFile
        else
          "./.github/workflows/${jsName}.yml";
    in
    {
      uses = usesPath;
      secrets = "inherit";
    }
    // lib.optionalAttrs (callerNeeds != [ ]) { needs = callerNeeds; }
    // lib.optionalAttrs (js.github-actions.reusableWorkflowInputs != { }) {
      "with" = js.github-actions.reusableWorkflowInputs;
    }
    // lib.optionalAttrs (js.github-actions.callerIf != null) {
      "if" = js.github-actions.callerIf;
    };

  # transformJobName is applied to job-set names when used as caller job IDs,
  # so that job-set names with characters invalid in GitHub Actions identifiers
  # (e.g. ":") are sanitised the same way individual job names are.
  # The workflow filename (jsName.yml) uses the raw job-set name, not the
  # transformed one, so that the filename is stable and user-controlled.
  callerJobSetJobs = lib.mapAttrs' (
    jsName: js: lib.nameValuePair (transformJobName jsName) (callerJobForJobSet jsName js)
  ) reusableJobSets;

  # -----------------------------------------------------------------------
  # Reusable workflow settings (one attrset per opted-in job-set)
  # -----------------------------------------------------------------------

  # Strip cross-job-set references from a rendered job inside a reusable workflow.
  # GitHub Actions reusable workflows cannot reference jobs from other workflows,
  # so we drop any `needs` entries that belong to a different job-set.
  # Ordering across job-sets is guaranteed at the caller level via `needs` on the
  # `workflow_call` job in ci.yaml.
  #
  # `intraJobNames` is a lookup set (name -> true) of transformed job names
  # that belong to the same job-set (plus the special "changes" job name).
  stripExternalNeeds =
    intraJobNames: job:
    let
      filteredNeeds = builtins.filter (n: intraJobNames ? ${n}) (job.needs or [ ]);

      # The `if` expression is "${{ COND1 && COND2 && ... }}".
      # Each optional-need condition has the form:
      #   (needs.JOB.result == 'success' || needs.JOB.result == 'skipped')
      # Strip conditions for jobs we removed from needs.
      removedNeeds = builtins.filter (n: !(intraJobNames ? ${n})) (job.needs or [ ]);
      filteredIf =
        if removedNeeds == [ ] || !(job ? "if") then
          job."if" or null
        else
          let
            rawExpr = lib.removePrefix "\${{ " (lib.removeSuffix " }}" job."if");
            conditions = lib.splitString " && " rawExpr;
            isExternalNeedCond =
              cond:
              builtins.any (
                n: cond == "(needs.${n}.result == 'success' || needs.${n}.result == 'skipped')"
              ) removedNeeds;
            keptConditions = builtins.filter (c: !(isExternalNeedCond c)) conditions;
          in
          if keptConditions == [ ] then null else "\${{ ${lib.concatStringsSep " && " keptConditions} }}";
    in
    builtins.removeAttrs job [
      "needs"
      "if"
    ]
    // lib.optionalAttrs (filteredNeeds != [ ]) { needs = filteredNeeds; }
    // lib.optionalAttrs (filteredIf != null) { "if" = filteredIf; };

  reusableWorkflowSettingForJobSet =
    _jsName: js:
    let
      # Jobs in this job-set
      jsEnabledJobs = lib.filterAttrs (name: _: builtins.elem name js.jobs) reusableEnabledJobs;

      # Intra-job-set transformed job names + "changes" (the changes job lives in the same reusable workflow)
      jsJobNames = lib.genAttrs (map transformJobName js.jobs ++ [ "changes" ]) (_: true);

      # Render jobs the same way as inline rendering, then strip cross-set needs
      renderedJobs = lib.mapAttrs' (name: job: {
        name = transformJobName name;
        value = stripExternalNeeds jsJobNames (builtins.removeAttrs job.github-actions [ "enable" ]);
      }) jsEnabledJobs;

      # Changes entries scoped to this job-set's jobs only
      jsChanges = mkChangesEntries jsEnabledJobs;
    in
    mkReusableWorkflow {
      jobs = renderedJobs;
      changes = jsChanges;
      inherit checkoutAction defaultRunsOn;
    };

in
{
  pipeline.github-actions = {
    settings.jobs = lib.mkMerge [
      # Inline changes job (for inline and redirecting reusable jobs with path filters)
      (lib.mkIf hasOuterChanges {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = defaultRunsOn;
          steps = [
            { uses = checkoutAction; }
            {
              id = "diff";
              shell = "bash";
              env = {
                DIFF_PATHS = builtins.concatStringsSep "\n" allOuterChanges;
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
      })

      # Inline jobs (rendered as before)
      (lib.mapAttrs' (name: job: {
        name = transformJobName name;
        value = builtins.removeAttrs job.github-actions [ "enable" ];
      }) inlineEnabledJobs)

      # Caller jobs for reusable job-sets
      callerJobSetJobs
    ];

    reusableWorkflowSettings = lib.mapAttrs reusableWorkflowSettingForJobSet generatingJobSets;
  };
}
