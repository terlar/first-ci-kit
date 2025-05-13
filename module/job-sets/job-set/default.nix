{
  lib,
  config,
  rootConfig,
  ...
}:

let
  inherit (rootConfig) jobs;
in
{
  imports = [ ./interface.nix ];

  config = {
    jobs = lib.pipe jobs [
      (lib.filterAttrs (_: job: (lib.intersectLists job.tags config.tags) != [ ]))
      builtins.attrNames
    ];
  };
}
