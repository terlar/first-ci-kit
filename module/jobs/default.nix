{ lib, config, ... }:

let
  cfg = config.jobs;
  enabledJobs = lib.filterAttrs (_: builtins.getAttr "enable") cfg;
in
{
  imports = [ ./interface.nix ];

  config = {
    pipeline = {
      github-actions.settings.jobs = lib.mapAttrs (_: job: job.github-actions) enabledJobs;
      gitlab-ci.settings = lib.mapAttrs (_: job: job.gitlab-ci) enabledJobs;
    };
  };
}
