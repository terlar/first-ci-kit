{ lib, ... }:

let
  inherit (lib) types;
in
{
  options.jobProfiles = lib.mkOption {
    type = types.lazyAttrsOf types.raw;
    default = { };
    description = "Job Profiles to use for common type of jobs.";
  };
}
