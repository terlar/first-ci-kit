{ lib, config, ... }:

let
  enabledForBackend =
    backend: lib.filterAttrs (_: job: job.enable && job.${backend}.enable) config.jobs;

  # Jobs that delegate to a child pipeline via pipelineCall. These are
  # suppressed from GitLab CI job rendering (enable = false) but still need an
  # include: entry in the parent pipeline.
  pipelineCallJobs = lib.filterAttrs (_: job: job.enable && job.pipelineCall != null) config.jobs;
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
        value = builtins.removeAttrs job.gitlab-ci [ "enable" ];
      }) (enabledForBackend "gitlab-ci"))

      (lib.mkIf (pipelineCallJobs != { }) {
        include = lib.mapAttrsToList (
          _: job:
          let
            pipeline = config.pipelines.${job.pipelineCall.pipeline};
            inherit (pipeline.gitlab-ci) templatePath;
          in
          assert lib.assertMsg (
            templatePath != null
          ) "pipelineCall: pipeline '${job.pipelineCall.pipeline}' has no gitlab-ci.templatePath set";
          let
            allInputs = job.pipelineCall.inputs // job.pipelineCall.gitlab-ci.extraInputs;
          in
          {
            local = templatePath;
          }
          // lib.optionalAttrs (allInputs != { }) {
            inputs = allInputs;
          }
        ) pipelineCallJobs;
      })
    ];

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: builtins.removeAttrs job.process-compose [ "enable" ]) (
        enabledForBackend "process-compose"
      );
    };
  };
}
