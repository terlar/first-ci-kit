{ lib, config, ... }:

let
  cfg = config.jobs;
in
{
  imports = [ ./interface.nix ];

  config = {
    pipeline.gitlab-ci.settings = lib.mapAttrs (_: job: job.gitlab-ci) cfg;
  };
}
