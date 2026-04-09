{ lib, config, ... }:

let
  inherit (config.pipeline.github-actions) checkoutAction defaultRunsOn transformJobName;
  mkReusableWorkflow = import ./reusable-workflow.nix { inherit lib; };

  enabledJobs = lib.filterAttrs (_: job: job.enable && job.github-actions.enable) config.jobs;

  # Job-sets that opted into reusable workflow generation
  reusableJobSets = lib.filterAttrs (_: js: js.github-actions.reusableWorkflow) config.jobSets;

  # Lookup set of job names belonging to any reusable job-set
  reusableJobNames = lib.genAttrs (lib.pipe reusableJobSets [
    builtins.attrValues
    (builtins.concatMap (js: js.jobs))
  ]) (_: true);

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

  # -----------------------------------------------------------------------
  # Caller: one workflow_call job per opted-in job-set
  # -----------------------------------------------------------------------
  callerJobForJobSet =
    jsName: js:
    let
      # For each needed job-set: if it's also reusable, use its name;
      # otherwise expand to individual job names (with transformJobName applied).
      callerNeeds = lib.unique (
        lib.pipe js.needs [
          (builtins.concatMap (
            { jobSet }:
            if reusableJobSets ? ${jobSet} then
              [ jobSet ]
            else
              map transformJobName config.jobSets.${jobSet}.jobs
          ))
        ]
      );
    in
    {
      uses = "./.github/workflows/${jsName}.yml";
      secrets = "inherit";
    }
    // lib.optionalAttrs (callerNeeds != [ ]) { needs = callerNeeds; };

  # Job-set names are used as-is (not run through transformJobName) because they
  # also serve as the reusable workflow filename and cross-set needs references.
  # Job-set names must already be valid GitHub Actions job identifiers.
  callerJobSetJobs = lib.mapAttrs callerJobForJobSet reusableJobSets;

  # -----------------------------------------------------------------------
  # Reusable workflow settings (one attrset per opted-in job-set)
  # -----------------------------------------------------------------------
  reusableWorkflowSettingForJobSet =
    _jsName: js:
    let
      # Jobs in this job-set
      jsEnabledJobs = lib.filterAttrs (name: _: builtins.elem name js.jobs) reusableEnabledJobs;

      # Render jobs the same way as inline rendering
      renderedJobs = lib.mapAttrs' (name: job: {
        name = transformJobName name;
        value = builtins.removeAttrs job.github-actions [ "enable" ];
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
      # Inline changes job (for inline jobs with path filters only)
      (lib.mkIf (inlineChanges != [ ]) {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = defaultRunsOn;
          steps = [
            { uses = checkoutAction; }
            {
              id = "diff";
              shell = "bash";
              env = {
                DIFF_PATHS = builtins.concatStringsSep "\n" inlineChanges;
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

    reusableWorkflowSettings = lib.mapAttrs reusableWorkflowSettingForJobSet reusableJobSets;
  };
}
