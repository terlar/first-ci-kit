{ lib, config, ... }:

let
  enabledJobs = lib.filterAttrs (_: builtins.getAttr "enable") config.jobs;
in
{
  imports = [
    ./interface.nix
    ./github-actions
  ];

  config.pipeline = {
    gitlab-ci.settings = lib.mapAttrs' (name: job: {
      name = config.pipeline.gitlab-ci.transformJobName name;
      value = lib.filterAttrs (n: _: n != "enable") job.gitlab-ci;
    }) enabledJobs;

    process-compose.settings = {
      processes = lib.mapAttrs (
        _: job: lib.filterAttrs (n: _: n != "enable") job.process-compose
      ) enabledJobs;
    };
  };
}
