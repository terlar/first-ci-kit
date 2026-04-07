{ lib, config, ... }:

let
  enabledForBackend =
    backend: lib.filterAttrs (_: job: job.enable && job.${backend}.enable) config.jobs;
in
{
  imports = [
    ./interface.nix
    ./github-actions
  ];

  config.pipeline = {
    gitlab-ci.settings = lib.mapAttrs' (name: job: {
      name = config.pipeline.gitlab-ci.transformJobName name;
      value = builtins.removeAttrs job.gitlab-ci [ "enable" ];
    }) (enabledForBackend "gitlab-ci");

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: builtins.removeAttrs job.process-compose [ "enable" ]) (
        enabledForBackend "process-compose"
      );
    };
  };
}
