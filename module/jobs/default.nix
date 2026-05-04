{
  lib,
  ci-lib,
  config,
  ...
}:

let
  enabledForBackend =
    backend: lib.filterAttrs (_: job: job.enable && job.${backend}.enable) config.jobs;

  # Jobs that delegate to a child pipeline via pipelineCall. These are
  # suppressed from GitLab CI job rendering (enable = false) but still need an
  # include: entry in the parent pipeline.
  pipelineCallJobs = lib.filterAttrs (_: job: job.enable && job.pipelineCall != null) config.jobs;

  resolveTemplatePath =
    pc:
    if pc.gitlab-ci.templatePath != null then
      pc.gitlab-ci.templatePath
    else
      assert lib.assertMsg (
        config.pipelines.${pc.pipeline}.gitlab-ci.templatePath != null
      ) "pipelineCall: pipeline '${pc.pipeline}' has no gitlab-ci.templatePath set";
      config.pipelines.${pc.pipeline}.gitlab-ci.templatePath;

  mkIncludeEntry =
    job:
    let
      pc = job.pipelineCall;
      jobRules = job.gitlab-ci.rules or [ ];
      augmentedBranches = ci-lib.augmentBranchesWithTriggers {
        inherit (job) branches triggers;
        inherit (config) jobs;
      };
      computedRules = lib.mergeAttrsList [
        (lib.optionalAttrs (pc.gitlab-ci.rulesInput != null) {
          ${pc.gitlab-ci.rulesInput} = jobRules ++ (ci-lib.mkBranchRules augmentedBranches).allRules;
        })
        (lib.optionalAttrs (pc.gitlab-ci.pushRulesInput != null) {
          ${pc.gitlab-ci.pushRulesInput} = jobRules ++ (ci-lib.mkBranchRules augmentedBranches).pushRules;
        })
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
  imports = [
    ./interface.nix
    ./github-actions.nix
  ];

  config = {
    gitlab-ci.settings = lib.mkMerge [
      (lib.mapAttrs' (name: job: {
        name = config.gitlab-ci.transformJobName name;
        value = lib.filterAttrs (_: v: v != { }) (builtins.removeAttrs job.gitlab-ci [ "enable" ]);
      }) (enabledForBackend "gitlab-ci"))

      (lib.mkIf (pipelineCallJobs != { }) {
        include = lib.mapAttrsToList (_: mkIncludeEntry) pipelineCallJobs;
      })
    ];

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: builtins.removeAttrs job.process-compose [ "enable" ]) (
        enabledForBackend "process-compose"
      );
    };
  };
}
