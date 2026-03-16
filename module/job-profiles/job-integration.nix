{
  lib,
  config,
  rootConfig,
  options,
  ...
}:

let
  inherit (lib) types;
  inherit (rootConfig) jobProfiles;
  jobProfile = if config.profile != null then jobProfiles.${config.profile} or { } else { };

  jobOptionNames = lib.pipe options [
    (lib.flip builtins.removeAttrs [
      "_module"
      "profile"
      "tags"
    ])
    builtins.attrNames
  ];
in
{
  options.profile = lib.mkOption {
    type = types.nullOr types.str;
    default = null;
    description = "Profile to use for the job.";
  };

  config = lib.mkIf (jobProfile != { }) (
    lib.genAttrs jobOptionNames (n: lib.mkIf (jobProfile ? ${n}) jobProfile.${n})
  );
}
