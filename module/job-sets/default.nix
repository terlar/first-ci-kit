{ lib, ci-lib, ... }:

{
  imports = [ ./interface.nix ];

  options.jobs = lib.mkOption {
    type = lib.types.lazyAttrsOf (
      lib.types.submoduleWith {
        modules = [ ./job-integration.nix ];
        specialArgs = {
          inherit ci-lib;
        };
      }
    );
  };
}
