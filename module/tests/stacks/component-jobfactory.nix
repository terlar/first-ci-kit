{ lib, test-lib, ... }:

let
  mkFactory =
    {
      stack,
      component,
      deployment,
      factoryName,
      formatJobName,
      ...
    }:
    {
      jobs.${
        formatJobName [
          stack
          component
          deployment
        ]
      } =
        { inherit factoryName; };
      jobSets = { };
    };

  baseConfig = {
    jobFactories.factory-a.fn = mkFactory;
    jobFactories.factory-b.fn = mkFactory;
    pipelines = { };
  };
in

{
  # Component jobFactory overrides stack jobFactory
  test-component-jobfactory-overrides-stack = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              jobFactory = "factory-a";
              deployments.dev = { };
              components = {
                alpha = { };
                beta.jobFactory = "factory-b";
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (cfg: {
            alpha = cfg.jobs.app_alpha_dev.factoryName;
            beta = cfg.jobs.app_beta_dev.factoryName;
          })
        ];
    expected = {
      alpha = "factory-a";
      beta = "factory-b";
    };
  };

  # Component jobFactory falls back to stack jobFactory when null
  test-component-jobfactory-falls-back-to-stack = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              jobFactory = "factory-b";
              deployments.dev = { };
              components.alpha = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_alpha_dev"
            "factoryName"
          ])
        ];
    expected = "factory-b";
  };

  # Component jobFactory falls back to defaultJobFactory when stack is also null
  test-component-jobfactory-falls-back-to-default = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            defaultJobFactory = "factory-a";
            stacks.app = {
              deployments.dev = { };
              components.alpha = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_alpha_dev"
            "factoryName"
          ])
        ];
    expected = "factory-a";
  };
}
