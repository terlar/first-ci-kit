{ lib, ... }:

let
  inherit (lib) types;
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
