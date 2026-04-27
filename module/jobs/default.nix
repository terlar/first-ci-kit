{ lib, config, ... }:

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
    pc:
    let
      allInputs = pc.inputs // pc.gitlab-ci.extraInputs;
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
        include = lib.mapAttrsToList (_: job: mkIncludeEntry job.pipelineCall) pipelineCallJobs;
      })
    ];

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: builtins.removeAttrs job.process-compose [ "enable" ]) (
        enabledForBackend "process-compose"
      );
    };
  };
}
