{ lib, config, ... }:

let
  enabledForBackend =
    backend: lib.filterAttrs (_: job: job.enable && job.${backend}.enable) config.jobs;
in
{
  imports = [
    ./interface.nix
    ./github-actions.nix
  ];

  config = {
    gitlab-ci.settings = lib.mapAttrs' (name: job: {
      name = config.gitlab-ci.transformJobName name;
      value = builtins.removeAttrs job.gitlab-ci [ "enable" ];
    }) (enabledForBackend "gitlab-ci");

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: builtins.removeAttrs job.process-compose [ "enable" ]) (
        enabledForBackend "process-compose"
      );
    };
  };
}
