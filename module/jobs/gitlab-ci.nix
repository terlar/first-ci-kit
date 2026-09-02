{
  lib,
  ci-lib,
  config,
  allPipelines ? { },
  ...
}:

let
  inherit (ci-lib.gitlab-ci) substituteInputs;
  enabledJobs = lib.filterAttrs (_: job: job.enable && job.gitlab-ci.enable) config.jobs;

  # Jobs that delegate to a child pipeline via pipelineCall. These are
  # suppressed from regular job rendering but still need an include: entry.
  pipelineCallJobs = lib.filterAttrs (_: job: job.enable && job.pipelineCall != null) config.jobs;

  # Resolve the GitLab CI template path for a pipelineCall. The per-call
  # override wins, then the nested child pipeline definition, and finally
  # the top-level allPipelines registry (with an assertion).
  resolveTemplatePath =
    pc:
    if pc.gitlab-ci.templatePath != null then
      pc.gitlab-ci.templatePath
    else if
      config.pipelines ? ${pc.pipeline} && config.pipelines.${pc.pipeline}.gitlab-ci.templatePath != null
    then
      config.pipelines.${pc.pipeline}.gitlab-ci.templatePath
    else
      assert lib.assertMsg (
        allPipelines ? ${pc.pipeline} && allPipelines.${pc.pipeline}.gitlab-ci.templatePath != null
      ) "pipelineCall: pipeline '${pc.pipeline}' has no gitlab-ci.templatePath set";
      allPipelines.${pc.pipeline}.gitlab-ci.templatePath;

  resolveInputs =
    job:
    let
      pc = job.pipelineCall;
      gl = pc.gitlab-ci;
      jobRules = job.gitlab-ci.rules or [ ];

      # Only compute branch rules when at least one rules input is configured.
      hasRulesInput = lib.any (x: x != null) [
        gl.rulesInput
        gl.allRulesInput
        gl.pushRulesInput
      ];
      branchRules =
        lib.pipe
          {
            inherit (job) branches triggers;
            inherit (config) jobs;
          }
          [
            ci-lib.gitlab-ci.augmentBranchesWithTriggers
            ci-lib.gitlab-ci.mkBranchRules
            (lib.optionalAttrs hasRulesInput)
          ];

      pipelineCallNeeds = lib.filter (
        need: config.jobs ? ${need.job} && config.jobs.${need.job}.pipelineCall != null
      ) job.needs;

      # Map each needsInputs entry to a list of child job needs objects.
      # Drop entries that resolve to an empty list (no pipelineCall deps).
      computedNeedsInputs = lib.filterAttrs (_: v: v != [ ]) (
        lib.mapAttrs (
          _: childJobSuffix:
          lib.map (need: {
            job = config.jobs.${need.job}.pipelineCall.gitlab-ci.toChildJobName childJobSuffix;
            optional = true;
            artifacts = false;
          }) pipelineCallNeeds
        ) gl.needsInputs
      );

      allRules = jobRules ++ (branchRules.allRules or [ ]);
      pushRules = jobRules ++ (branchRules.pushRules or [ ]);
    in
    pc.inputs
    // pc.gitlab-ci.extraInputs
    // lib.optionalAttrs (gl.rulesInput != null) { ${gl.rulesInput} = allRules; }
    // lib.optionalAttrs (gl.allRulesInput != null) { ${gl.allRulesInput} = allRules; }
    // lib.optionalAttrs (gl.pushRulesInput != null) { ${gl.pushRulesInput} = pushRules; }
    // computedNeedsInputs;

  resolvedJobs = lib.mapAttrs (_: job: {
    inherit job;
    inputs = resolveInputs job;
  }) pipelineCallJobs;

  mkIncludeEntry =
    { job, inputs }:
    {
      local = resolveTemplatePath job.pipelineCall;
    }
    // lib.optionalAttrs (inputs != { }) { inherit inputs; };

  resolveChildPipeline =
    pc:
    config.pipelines.${pc.pipeline} or allPipelines.${pc.pipeline}
      or (throw "pipelineCall (inline): pipeline '${pc.pipeline}' not found in pipelines or allPipelines");

  mkInlineJobs =
    { job, inputs }:
    let
      childPipeline = resolveChildPipeline job.pipelineCall;
      # Merge defaults of unprovided inputs into substitution map.
      finalInputs =
        inputs
        // lib.pipe (childPipeline.inputs or { }) [
          (lib.filterAttrs (name: _: !(inputs ? ${name})))
          (lib.mapAttrs (_: def: def.default or null))
          (lib.filterAttrs (_: v: v != null))
        ];
    in
    lib.pipe childPipeline.gitlab-ci.settings [
      (lib.flip builtins.removeAttrs [
        "cache"
        "default"
        "image"
        "include"
        "services"
        "stages"
        "variables"
        "workflow"
      ])
      (lib.mapAttrs' (
        name: value: {
          name = substituteInputs finalInputs name;
          value = substituteInputs finalInputs value;
        }
      ))
    ];
in
{
  config.gitlab-ci.settings = lib.mkMerge [
    (lib.mapAttrs' (name: job: {
      name = config.gitlab-ci.transformJobName name;
      value = lib.filterAttrs (_: v: v != { }) (builtins.removeAttrs job.gitlab-ci [ "enable" ]);
    }) enabledJobs)

    (lib.mkIf (!config.gitlab-ci.inlinePipelineCalls && pipelineCallJobs != { }) {
      include = lib.mapAttrsToList (_: mkIncludeEntry) resolvedJobs;
    })

    (lib.mkIf (config.gitlab-ci.inlinePipelineCalls && pipelineCallJobs != { }) (
      lib.mkMerge (lib.mapAttrsToList (_: mkInlineJobs) resolvedJobs)
    ))
  ];
}
