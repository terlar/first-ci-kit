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
                example = "networking";
              };
              component = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Component name of the dependency. When null, depends on the
                  stack-level jobSet (all components of the target stack at
                  the same deployment).
                '';
                example = "vpc";
              };
            };
          }
        );
        default = [ ];
        description = ''
          Dependencies on other components or stacks. Needs are always resolved
          within the same deployment as the declaring component — cross-deployment
          needs are not supported.

          Use `{ component = "name"; }` for a sibling component in the same stack,
          `{ stack = "name"; }` for all components of another stack, or
          `{ stack = "name"; component = "name"; }` for a specific component in
          another stack.
        '';
        example = lib.literalExpression ''
          [
            { component = "vpc"; }
            { stack = "security"; component = "iam"; }
          ]
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

          The factory `fn` receives
          `{ stack, component, deployment, needs, formatJobName, factoryName }`
          and must return `{ jobs, jobSets }`.
        '';
        example = lib.literalExpression ''"tofu-component"'';
      };

      deployments = lib.mkOption {
        type = types.lazyAttrsOf (
          types.submodule {
            config._module.freeformType = types.attrs;
          }
        );
        default = { };
        description = ''
          Deployment environments for this stack. Only the attribute names
          matter; values are not currently used.
        '';
        example = lib.literalExpression ''
          {
            dev = { };
            stg = { };
            prod = { };
          }
        '';
      };

      components = lib.mkOption {
        type = types.lazyAttrsOf (
          types.submoduleWith {
            modules = [ componentModule ];
          }
        );
        default = { };
        description = ''
          Components within this stack. Each component generates one job per
          deployment via the stack's factory.
        '';
        example = lib.literalExpression ''
          {
            vpc = { };
            dns.needs = [ { component = "vpc"; } ];
            cluster.needs = [ { component = "vpc"; } { component = "dns"; } ];
          }
        '';
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
      example = lib.literalExpression ''"tofu-component"'';
    };

    stacks = lib.mkOption {
      type = types.lazyAttrsOf (
        types.submoduleWith {
          modules = [ stackModule ];
        }
      );
      default = { };
      description = ''
        Infrastructure stacks topology. Each stack declares its deployment
        environments and components. The stack engine generates one factory
        application per component × deployment combination and resolves
        cross-component `needs` within each deployment.
      '';
      example = lib.literalExpression ''
        {
          networking = {
            deployments = { dev = { }; prod = { }; };
            components = {
              vpc = { };
              dns.needs = [ { component = "vpc"; } ];
            };
          };
          cluster = {
            deployments = { dev = { }; prod = { }; };
            components = {
              control-plane.needs = [ { stack = "networking"; } ];
              node-pools.needs    = [ { component = "control-plane"; } ];
            };
          };
        }
      '';
    };
  };
}
