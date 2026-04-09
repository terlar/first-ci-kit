{
  lib,
  ci-lib,
  name,
  config,
  rootConfig,
  options,
  ...
}:

let
  matchedJobSets = lib.filterAttrs (
    _: jobSet: (builtins.elem name jobSet.jobs) || (lib.intersectLists jobSet.tags config.tags) != [ ]
  ) rootConfig.jobSets;

  jobOptionNames = lib.pipe options [
    (lib.flip builtins.removeAttrs [
      "_module"
      "artifacts"
      "tags"
    ])
    builtins.attrNames
  ];

  jobSetDefaults = lib.pipe matchedJobSets [
    builtins.attrValues
    (builtins.catAttrs "jobDefaults")
    (lib.foldAttrs (item: acc: [ item ] ++ acc) [ ])
  ];
in
{
  config = lib.mkIf (matchedJobSets != { }) (
    lib.mkMerge [
      {
        needs = lib.pipe matchedJobSets [
          builtins.attrValues
          (map (set: set.needs))
          lib.flatten
          (map ({ jobSet, ... }: rootConfig.jobSets.${jobSet}.jobs))
          lib.flatten
          (map ci-lib.jobToNeed)
        ];
      }
      (lib.genAttrs jobOptionNames (
        n: lib.mkIf (jobSetDefaults ? ${n}) (lib.mkMerge jobSetDefaults.${n})
      ))
    ]
  );
}
