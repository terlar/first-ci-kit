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

  deploymentMatchModule = {
    options = {
      environment = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Match target deployments by `environment` value.

          - `null` (default): match targets whose `environment` equals the
            current deployment's `environment`.
          - A string: match targets whose `environment` equals this value.
        '';
        example = lib.literalExpression ''"prod"'';
      };
    };
  };

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
              deployment = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
                description = ''
                  Explicit deployment name of the dependency. When null and
                  `matchDeployment` is also null, the target deployment is the
                  same name as the current deployment. Ignored when
                  `matchDeployment` is set.
                '';
                example = "dev_tooling";
              };
              matchDeployment = lib.mkOption {
                type = types.nullOr (
                  types.submoduleWith {
                    modules = [ deploymentMatchModule ];
                  }
                );
                default = null;
                description = ''
                  When non-null, resolve to all deployments of the target
                  stack/component whose deployment settings match every
                  attribute in this set. A `null` attribute value means
                  "match targets whose value for that attribute equals the
                  current deployment's value". Produces zero jobSets when no
                  deployment matches. When null (the default), the target
                  deployment is resolved by the `deployment` field (or the
                  current deployment name when `deployment` is also null).
                '';
                example = lib.literalExpression ''
                  { environment = null; }   # same environment as current deployment
                '';
              };
            };
          }
        );
        default = [ ];
        description = ''
          Dependencies on other components or stacks. By default needs are
          resolved within the same deployment as the declaring component.

          Use `{ component = "name"; }` for a sibling component in the same stack,
          `{ stack = "name"; }` for all components of another stack, or
          `{ stack = "name"; component = "name"; }` for a specific component in
          another stack. Set `deployment = "name"` to pin to a specific deployment,
          or `matchDeployment = { environment = null; }` to match all deployments
          whose `environment` value equals the current deployment's `environment`.
        '';
        example = lib.literalExpression ''
          [
            { component = "vpc"; }
            { stack = "security"; component = "iam"; }
            { component = "network"; matchDeployment.environment = null; }
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

      jobFactory = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Name of a factory in `config.jobFactories` used for this component.
          When null, falls back to the stack's `jobFactory`, then to
          `config.defaultJobFactory`.
        '';
        example = lib.literalExpression ''"tofu-component"'';
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
