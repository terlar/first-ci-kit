{
  lib,
  ci-lib,
  config,
  allPipelines ? { },
  ...
}:

let
  enabledJobs = lib.filterAttrs (_: job: job.enable && job.gitlab-ci.enable) config.jobs;

  # Jobs that delegate to a child pipeline via pipelineCall. These are
  # suppressed from regular job rendering but still need an include: entry.
  pipelineCallJobs = lib.filterAttrs (_: job: job.enable && job.pipelineCall != null) config.jobs;

  # Resolve the GitLab CI template path for a pipelineCall. The per-call
  # override wins, then the nested child pipeline definition, and finally
  # the top-level allPipelines registry (with an assertion).
  resolveTemplatePath =
    pc:
    lib.findFirst (x: x != null)
      (
        assert lib.assertMsg (
          allPipelines ? ${pc.pipeline} && allPipelines.${pc.pipeline}.gitlab-ci.templatePath != null
        ) "pipelineCall: pipeline '${pc.pipeline}' has no gitlab-ci.templatePath set";
        allPipelines.${pc.pipeline}.gitlab-ci.templatePath
      )
      [
        # 1. Per-call explicit override wins.
        pc.gitlab-ci.templatePath
        # 2. Child pipeline definition (nested under this pipeline).
        (config.pipelines.${pc.pipeline}.gitlab-ci.templatePath or null)
      ];

  mkIncludeEntry =
    job:
    let
      pc = job.pipelineCall;
      jobRules = job.gitlab-ci.rules or [ ];
      augmentedBranches = ci-lib.gitlab-ci.augmentBranchesWithTriggers {
        inherit (job) branches triggers;
        inherit (config) jobs;
      };

      pipelineCallNeeds = builtins.filter (
        need: config.jobs ? ${need.job} && config.jobs.${need.job}.pipelineCall != null
      ) job.needs;

      computedNeedsInputs = lib.pipe pc.gitlab-ci.needsInputs [
        (lib.mapAttrs (
          _inputName: childJobSuffix:
          map (need: {
            job = config.jobs.${need.job}.pipelineCall.gitlab-ci.toChildJobName childJobSuffix;
            optional = true;
            artifacts = false;
          }) pipelineCallNeeds
        ))
        (lib.filterAttrs (_: v: v != [ ]))
      ];

      computedRules = lib.mergeAttrsList [
        (lib.optionalAttrs (pc.gitlab-ci.rulesInput != null) {
          ${pc.gitlab-ci.rulesInput} =
            jobRules ++ (ci-lib.gitlab-ci.mkBranchRules augmentedBranches).allRules;
        })
        (lib.optionalAttrs (pc.gitlab-ci.allRulesInput != null) {
          ${pc.gitlab-ci.allRulesInput} =
            jobRules ++ (ci-lib.gitlab-ci.mkBranchRules augmentedBranches).allRules;
        })
        (lib.optionalAttrs (pc.gitlab-ci.pushRulesInput != null) {
          ${pc.gitlab-ci.pushRulesInput} =
            jobRules ++ (ci-lib.gitlab-ci.mkBranchRules augmentedBranches).pushRules;
        })
        computedNeedsInputs
      ];
      allInputs = lib.mergeAttrsList [
        pc.inputs
        pc.gitlab-ci.extraInputs
        computedRules
      ];
    in
    { local = resolveTemplatePath pc; } // lib.optionalAttrs (allInputs != { }) { inputs = allInputs; };
in
{
  config.gitlab-ci.settings = lib.mkMerge [
    (lib.mapAttrs' (name: job: {
      name = config.gitlab-ci.transformJobName name;
      value = lib.filterAttrs (_: v: v != { }) (builtins.removeAttrs job.gitlab-ci [ "enable" ]);
    }) enabledJobs)

    (lib.mkIf (pipelineCallJobs != { }) {
      include = lib.mapAttrsToList (_: mkIncludeEntry) pipelineCallJobs;
    })
  ];
}
