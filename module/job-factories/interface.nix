{ lib, ... }:

let
  inherit (lib) types;
in
{
  options = {
    jobFactories = lib.mkOption {
      type = types.lazyAttrsOf (
        types.submodule {
          options = {
            fn = lib.mkOption {
              type = types.functionTo types.attrs;
              description = ''
                Factory function that takes arguments and returns an attrset of
                config options (e.g. `{ jobs = {...}; jobSets = {...}; }`).
              '';
            };

            applications = lib.mkOption {
              type = types.listOf types.attrs;
              default = [ ];
              description = ''
                List of argument attrsets to apply to `fn`. Each entry calls
                `fn <args>` and merges the result into the pipeline config.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Job factories that produce pipeline-level config. Each factory has a
        `fn` that takes arguments and an `applications` list of argument
        attrsets to apply.
      '';
    };
  };
}
