{ lib, config, ... }:

let
  applied = lib.pipe config.jobFactories [
    lib.attrValues
    (lib.concatMap (factory: map factory.fn factory.applications))
  ];
  applyAll = attr: lib.mkMerge (builtins.catAttrs attr applied);
in
{
  imports = [ ./interface.nix ];

  config = {
    jobs = applyAll "jobs";
    jobSets = applyAll "jobSets";
  };
}
