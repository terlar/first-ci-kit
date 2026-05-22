{ lib, test-lib, ... }:

let
  tofuFactory =
    {
      stack,
      component,
      deployment,
      ...
    }:
    let
      jobName = builtins.concatStringsSep "_" [
        stack
        component
        deployment
      ];
    in
    {
      jobs.${jobName} = { };
      jobSets.${jobName} = { };
    };

  baseConfig = {
    defaultJobFactory = "tofu";
    jobFactories.tofu.fn = tofuFactory;
  };
in

{
  # 1. Component with null deployments inherits from stack
  test-stacks-component-inherits-stack-deployments = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments = {
                dev = { };
                prod = { };
              };
              components.api = { }; # deployments = null → inherits
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "app_api_dev"
      "app_api_prod"
    ];
  };

  # 2. Component with explicit deployments overrides stack-level deployments
  test-stacks-component-overrides-deployments = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments = {
                dev = { };
                prod = { };
              };
              components.api.deployments = {
                stg = { };
              };
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [ "app_api_stg" ];
  };

  # 3. Mixed: one component inherits, another overrides
  test-stacks-mixed-component-deployments = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments = {
                dev = { };
                prod = { };
              };
              components = {
                api = { }; # inherits dev + prod
                worker.deployments.dev = { }; # only dev
              };
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "app_api_dev"
      "app_api_prod"
      "app_worker_dev"
    ];
  };
}
