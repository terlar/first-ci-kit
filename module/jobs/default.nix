{ lib, config, ... }:

let
  cfg = config.jobs;
  enabledJobs = lib.filterAttrs (_: builtins.getAttr "enable") cfg;
in
{
  imports = [ ./interface.nix ];

  config.pipeline = {
    github-actions.settings.jobs = lib.mapAttrs' (name: job: {
      name = config.pipeline.github-actions.transformJobName name;
      value = job.github-actions;
    }) enabledJobs;

    gitlab-ci.settings = lib.mapAttrs' (name: job: {
      name = config.pipeline.gitlab-ci.transformJobName name;
      value = job.gitlab-ci;
    }) enabledJobs;

    process-compose.settings = {
      processes = lib.mapAttrs (_: job: job.process-compose) enabledJobs;
    };
  };
}
