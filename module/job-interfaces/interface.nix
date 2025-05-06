{ lib, ... }:

let
  inherit (lib) types;
in
{
  options.jobInterfaces = lib.mkOption {
    type = types.lazyAttrsOf (types.functionTo (types.lazyAttrsOf types.deferredModule));
    default = { };
    description = "Job Interfaces to define jobs.";
  };
}
