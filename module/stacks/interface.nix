{ lib, ... }:

let
  inherit (lib) types;

  componentModule = {
    options = {
      needs = lib.mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              stack = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Stack name of the dependency. When null, uses the current stack.";
              };
              component = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Component name of the dependency. When null, matches all components (stack-level jobSet).";
              };
            };
          }
        );
        default = [ ];
        description = ''
          Dependencies on other components or stacks. Resolved within the same deployment.

          Note: needs are always resolved within the same deployment as the declaring component.
          Cross-deployment needs are not supported.
        '';
      };
    };
  };

  stackModule = {
    options = {
      jobFactory = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Name of a factory in `config.jobFactories` used to generate jobs and
          jobSets for each component × deployment combination in this stack.
          When null, falls back to `config.defaultJobFactory`.
          The factory receives `{ stackName, componentName, deployment, stack,
          component, needs }` and must return `{ jobs, jobSets }`.
        '';
      };

      deployments = lib.mkOption {
        type = types.lazyAttrsOf (
          types.submodule {
            config._module.freeformType = types.attrs;
          }
        );
        default = { };
        description = "Deployment environments for this stack (e.g. dev, stg, prod). Values are not currently used; only the names matter.";
      };

      components = lib.mkOption {
        type = types.lazyAttrsOf (
          types.submoduleWith {
            modules = [ componentModule ];
          }
        );
        default = { };
        description = "Components within this stack.";
      };
    };
  };
in
{
  options = {
    defaultJobFactory = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Default factory name used for stacks that do not set `jobFactory`.
        When both are null, an error is thrown at evaluation time.
      '';
    };

    stacks = lib.mkOption {
      type = types.lazyAttrsOf (
        types.submoduleWith {
          modules = [ stackModule ];
        }
      );
      default = { };
      description = "Infrastructure stacks topology. Each stack contains deployments and components.";
    };
  };
}
