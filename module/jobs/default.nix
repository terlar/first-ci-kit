{ lib, config, ... }:

let
  cfg = config.jobs;
in
{
  imports = [ ./interface.nix ];

  config = {
    pipeline = {
      github-actions.settings.jobs = lib.mapAttrs (_: job: job.github-actions) cfg;
      gitlab-ci.settings = lib.mapAttrs (_: job: job.gitlab-ci) cfg;
    };
  };
}
