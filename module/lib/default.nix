{ lib, ... }:

let
  inherit (lib) types;

  expandPipelineNeed =
    jobSets: need:
    if need.jobSet != null then
      map (job: {
        inherit job;
        inherit (need) optional artifacts;
      }) jobSets.${need.jobSet}.jobs
    else
      [
        {
          inherit (need) job optional artifacts;
        }
      ];
in
{
  documentsToYAML = lib.concatMapStringsSep "---\n" (x: (builtins.toJSON x) + "\n");

  types.needsType = types.submoduleWith {
    description = "Needs configuration";
    modules = [
      {
        options = {
          job = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job.";
          };

          jobSet = lib.mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Name of the needed job set.";
          };

          optional = lib.mkOption {
            type = types.bool;
            default = false;
            description = "Whether need is optional.";
          };

          artifacts = lib.mkOption {
            type = types.bool;
            default = true;
            description = "Whether artifacts from dependency are used.";
          };
        };
      }
    ];
  };

  jobToNeed = job: {
    inherit job;
    artifacts = false;
    optional = true;
  };

  # Expand a single pipeline need given a jobSets attrset.
  # Returns a list of { job, optional, artifacts }.
  inherit expandPipelineNeed;

  # Expand a list of pipeline needs into a flat list of { job, optional, artifacts }.
  expandPipelineNeeds = jobSets: needs: lib.flatten (map (expandPipelineNeed jobSets) needs);

  replaceVariables =
    variables:
    let
      from = lib.pipe variables [
        builtins.attrNames
        (map (x: "{${x}}"))
      ];
      to = builtins.attrValues variables;
    in
    map (builtins.replaceStrings from to);
}
