{
  lib,
  config,
  ...
}:

let
  enabledForBackend =
    backend: lib.filterAttrs (_: job: job.enable && job.${backend}.enable) config.jobs;
in
{
  imports = [
    ./interface.nix
    ./github-actions.nix
    ./gitlab-ci.nix
  ];

  config.process-compose.settings = {
    processes = lib.mapAttrs (_: job: builtins.removeAttrs job.process-compose [ "enable" ]) (
      enabledForBackend "process-compose"
    );
  };
}
