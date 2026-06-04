{
  lib,
  ci-lib,
  config,
  allPipelines ? { },
  ...
}:

let
  inherit (config) jobs;
  inherit (ci-lib.process-compose) mkDependsOn;

  enabledJobs = lib.filterAttrs (_: job: job.enable && job.process-compose.enable) jobs;

  # Jobs that delegate to a child pipeline via pipelineCall.
  pipelineCallJobs = lib.filterAttrs (_: job: job.enable && job.pipelineCall != null) jobs;

  # Resolve a pipeline by name; config.pipelines takes priority over
  # allPipelines (the top-level registry from the flake).
  resolvePipeline =
    name:
    config.pipelines.${name} or allPipelines.${name}
      or (throw "pipelineCall (process-compose): pipeline '${name}' not found in pipelines or allPipelines");

  # The fields that are first-ci-kit-internal and must never appear in the
  # final process-compose output.
  internalFields = [
    "enable"
    "before_script"
    "command"
  ];

  # Build the process-compose process attrset for a single job, stripping
  # internal fields and prepending before_script to command when present.
  mkProcessConfig =
    job:
    let
      inherit (job.process-compose) before_script;
      finalCommand =
        before_script ++ lib.optional (job.process-compose ? command) job.process-compose.command;
    in
    lib.removeAttrs job.process-compose internalFields
    // lib.optionalAttrs (finalCommand != [ ]) { command = lib.concatStringsSep "\n" finalCommand; };

  # Inline a referenced child pipeline's processes into the parent pipeline's
  # process-compose configuration, namespaced as "${parentJobName}_${childJobName}".
  # A sentinel process "${parentJobName}" is created that depends_on all inlined
  # child processes, serving as the target for other parent jobs that need this
  # pipelineCall job.
  mkPipelineCallProcesses =
    parentJobName: job:
    let
      pc = job.pipelineCall;
      childPipeline = resolvePipeline pc.pipeline;

      # Only include jobs that are enabled and renderable; warn and skip any
      # child that is itself a pipelineCall (recursive inlining is not supported).
      enabledChildJobs = lib.filterAttrs (
        childJobName: cj:
        if cj.pipelineCall != null then
          lib.warn "process-compose: pipelineCall job '${childJobName}' in pipeline '${pc.pipeline}' (called from '${parentJobName}') cannot be recursively inlined; skipping" false
        else
          cj.enable && cj.process-compose.enable
      ) childPipeline.jobs;

      # Namespace a child job name under the parent job name.
      nsName = childJobName: "${parentJobName}_${childJobName}";

      parentDependsOn = mkDependsOn {
        inherit jobs;
        inherit (job) needs runAlways;
      };

      # Convert pipelineCall inputs to process-compose environment format
      # (uppercased key=value strings) so that child process commands can
      # reference them as shell variables, e.g. $STACK, $COMPONENT.
      inputsEnv = lib.mapAttrsToList (k: v: "${lib.toUpper k}=${v}") pc.inputs;

      inlinedProcesses = lib.mapAttrs' (
        childJobName: childJob:
        let
          childPc = childJob.process-compose;
          # Remap internal child depends_on keys to namespaced names.
          remappedDependsOn = lib.mapAttrs' (depName: lib.nameValuePair (nsName depName)) (
            childPc.depends_on or { }
          );
          # Inject parent depends_on into root child jobs (those with no
          # depends_on of their own) so they don't start before the parent
          # job's prerequisites are satisfied.
          finalDependsOn =
            if remappedDependsOn == { } then remappedDependsOn // parentDependsOn else remappedDependsOn;
          # Merge input vars before the child's own environment entries so that
          # child-defined values take precedence in case of a collision.
          mergedEnvironment = inputsEnv ++ (childPc.environment or [ ]);
        in
        {
          name = nsName childJobName;
          value =
            lib.removeAttrs (mkProcessConfig childJob) [
              "depends_on"
              "environment"
            ]
            // lib.optionalAttrs (mergedEnvironment != [ ]) {
              environment = mergedEnvironment;
            }
            // lib.optionalAttrs (finalDependsOn != { }) {
              depends_on = finalDependsOn;
            };
        }
      ) enabledChildJobs;

      # Sentinel: a no-op process that depends on all inlined child processes,
      # giving other parent jobs a single target to depend on.
      sentinel = {
        command = ''echo "Pipeline ${pc.pipeline} complete"'';
      }
      // lib.optionalAttrs (inlinedProcesses != { }) {
        depends_on = lib.mapAttrs (_: _: {
          condition = if job.runAlways then "process_completed" else "process_completed_successfully";
        }) inlinedProcesses;
      };
    in
    inlinedProcesses // { ${parentJobName} = sentinel; };
in
{
  config.process-compose.settings = {
    # Build the processes attrset as a plain union so that the value stored
    # in the deferredModule settings option remains directly readable when
    # evaluated (no nested lib.mkMerge wrappers around the attrset).
    processes =
      lib.pipe enabledJobs [
        (lib.filterAttrs (_: job: job.pipelineCall == null))
        (lib.mapAttrs (_: mkProcessConfig))
      ]
      // lib.pipe pipelineCallJobs [
        (lib.filterAttrs (_: job: job.process-compose.enable))
        (lib.mapAttrsToList mkPipelineCallProcesses)
        lib.mergeAttrsList
      ];
  };
}
