{
  lib,
  ci-lib,
  config,
  ...
}:

let
  jobNeedsFromSet =
    set:
    lib.pipe set.needs [
      (map ({ jobSet, ... }: config.jobSets.${jobSet}.jobs))
      lib.flatten
      (map ci-lib.jobToNeed)
    ];

  configureSetJobs =
    set:
    let
      needs = jobNeedsFromSet set;
    in
    lib.genAttrs set.jobs (
      _:
      lib.mkMerge [
        set.jobDefaults
        { inherit needs; }
      ]
    );
in
{
  imports = [ ./interface.nix ];

  config = {
    jobs = lib.pipe config.jobSets [
      (lib.mapAttrsToList (_: configureSetJobs))
      lib.mkMerge
    ];
  };
}
