{ lib, test-lib, ... }:

let
  baseConfig = {
    defaultJobFactory = "noop";
    jobFactories.noop.fn = _: {
      jobs = { };
      jobSets = { };
    };
    pipelines = { };
  };
in
{
  # Freeform attributes set on a component are accessible via config.stacks
  test-component-freeform-attr-readable = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api.customFlag = true;
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "app"
            "components"
            "api"
            "customFlag"
          ])
        ];
    expected = true;
  };

  # Multiple freeform attributes can be set on the same component
  test-component-freeform-multiple-attrs = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api = {
                hasPackage = true;
                priority = 42;
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (cfg: {
            inherit (cfg.stacks.app.components.api) hasPackage priority;
          })
        ];
    expected = {
      hasPackage = true;
      priority = 42;
    };
  };

  # Freeform attributes are independent per component
  test-component-freeform-per-component = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components = {
                alpha.hasPackage = true;
                beta = { };
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (cfg: {
            alpha = cfg.stacks.app.components.alpha.hasPackage or false;
            beta = cfg.stacks.app.components.beta.hasPackage or false;
          })
        ];
    expected = {
      alpha = true;
      beta = false;
    };
  };
}
