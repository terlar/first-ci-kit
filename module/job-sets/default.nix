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
    lib.genAttrs set.jobs (
      _:
      lib.mkMerge [
        set.jobDefaults
        { needs = jobNeedsFromSet set; }
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
