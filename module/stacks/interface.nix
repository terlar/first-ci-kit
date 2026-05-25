{ lib, ... }:

let
  inherit (lib) types;

  deploymentModule =
    { name, ... }:
    {
      options = {
        environment = lib.mkOption {
          type = types.nullOr types.str;
          default = name;
          description = ''
            Logical environment this deployment targets (e.g. "dev", "prod").
            Passed to the factory as part of `settings`. Defaults to the
            deployment name. Set to null to indicate no environment association.
          '';
          example = lib.literalExpression ''"prod"'';
        };
      };
      config._module.freeformType = types.attrs;
    };

  deploymentsType = types.lazyAttrsOf (
    types.submoduleWith {
      modules = [ deploymentModule ];
    }
  );

  mkDeploymentsOption =
    overrides:
    lib.mkOption (
      {
        type = deploymentsType;
        default = { };
        description = ''
          Deployment environments. Attribute names are the deployment keys used
          in job naming. Values may set `environment` (logical target environment)
          and any additional fields, which are passed to the job factory as
          `deploymentConfig` after module evaluation.
        '';
        example = lib.literalExpression ''
          {
            dev = { };
            stg = { };
            prod = { };
          }
        '';
      }
      // overrides
    );

  componentModule = {
    options = {
      deployments = mkDeploymentsOption {
        type = types.nullOr deploymentsType;
        default = null;
        description = ''
          Deployment environments for this component. When set, overrides the
          stack-level `deployments` for this component only. When null
          (the default), the component inherits the stack-level `deployments`.
        '';
      };

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

      extraPaths = lib.mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = ''
          Additional glob paths to include in change detection for this
          component, beyond what the job factory derives from
          stack/component/deployment. Passed to the factory as `extraPaths`.
        '';
        example = lib.literalExpression ''[ "shared/modules/**" "config/common.yaml" ]'';
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
          `{ stack, component, deployment, settings, needs, formatJobName, factoryName }`
          and must return `{ jobs, jobSets }`. `settings` contains all deployment
          fields (including `environment`) plus `extraPaths` from the component.
        '';
        example = lib.literalExpression ''"tofu-component"'';
      };

      deployments = mkDeploymentsOption { };

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
