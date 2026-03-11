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
      value = job.gitlab-ci;
    }) enabledJobs;

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: job.process-compose) enabledJobs;
    };
  };
}
