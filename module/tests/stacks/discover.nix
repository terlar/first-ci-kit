{ lib, test-lib, ... }:

let
  fakeTree = ./fixtures/stacks;
  fakeFlat = ./fixtures/flat;
  fakeDeploymentsMerge = ./fixtures/deployments-merge;

  tofuFactory =
    {
      stack,
      component,
      deployment,
      needs,
      ...
    }:
    {
      jobs."${stack}_${component}_${deployment}" = { };
      jobSets."${stack}_${component}_${deployment}" = {
        inherit needs;
      };
    };

  baseConfig = {
    defaultJobFactory = "tofu";
    jobFactories.tofu.fn = tofuFactory;
  };
in
{
  # Basic discovery: finds stacks, components and deployments from filesystem
  test-stackdiscovery-discovers-stacks-and-components = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "networking_vpc_dev"
      "networking_vpc_prod"
    ];
  };

  # excludeDirs skips listed top-level dirs (modules/ excluded by default)
  test-stackdiscovery-excludedirs-default = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
          }
        ]
        [
          test-lib.evalConfig
          (cfg: !(cfg.stacks ? "modules"))
        ];
    expected = true;
  };

  # Without excludeDirs, modules/ would be included (proves exclusion works)
  test-stackdiscovery-excludedirs-default-would-include-without-exclusion = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
              excludeDirs = [ ]; # don't exclude anything
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "modules_some-module_dev"
      "networking_vpc_dev"
      "networking_vpc_prod"
    ];
  };

  # excludeDirs can be overridden to skip specific stacks
  test-stackdiscovery-excludedirs-custom = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
              excludeDirs = [
                "modules"
                "networking"
              ];
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [ ];
  };

  # component.nix in component dir sets needs
  test-stackdiscovery-component-nix-sets-needs = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
            stacks.infra.components.db.deployments.dev = { };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobSets"
            "networking_vpc_dev"
            "needs"
          ])
        ];
    expected = [ { jobSet = "infra_db_dev"; } ];
  };

  # File-based detection with a custom extension
  test-stackdiscovery-custom-extension = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeFlat;
              deployments = {
                subdirectory = null;
                detection = "files";
                extension = ".tfvars";
              };
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "org_iam_acc"
      "org_iam_dev"
      "org_repository_dev"
    ];
  };

  # Disabled produces no stacks
  test-stackdiscovery-disabled-produces-nothing = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = false;
              path = fakeTree;
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") ];
    expected = { };
  };

  # Hand-written stacks win over discovered defaults
  test-stackdiscovery-handwritten-wins = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
            stacks.networking.components.vpc.deployments = {
              staging = { };
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    # explicit deployments override filesystem-discovered ones
    expected = [ "networking_vpc_staging" ];
  };

  # detection = "directories": subdirectories of the deployments subdir become deployment keys
  test-stackdiscovery-detection-directories = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "networking_vpc_dev"
      "networking_vpc_prod"
    ];
  };

  # subdirectory = null: deployment files sit directly in the component directory
  test-stackdiscovery-null-subdirectory = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeFlat;
              deployments.subdirectory = null;
              deployments.detection = "files";
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "org_iam_acc"
      "org_iam_dev"
      "org_repository_dev"
    ];
  };

  # stackName: path is treated as a single stack, no stack-level directory
  test-stackdiscovery-stackname = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = "${fakeFlat}/org";
              stackName = "org";
              deployments.subdirectory = null;
              deployments.detection = "files";
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "org_iam_acc"
      "org_iam_dev"
      "org_repository_dev"
    ];
  };

  # module: default is no-op
  test-stackdiscovery-module-default-noop = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "networking"
            "components"
            "vpc"
          ])
          (c: c ? "customAttr")
        ];
    expected = false;
  };

  # module: sets a freeform attribute via config.path
  test-stackdiscovery-module-sets-freeform-attr = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
              component.module =
                { config, ... }:
                {
                  hasPackage = builtins.pathExists "${config.path}/package/default.nix";
                };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "networking"
            "components"
            "vpc"
            "hasPackage"
          ])
        ];
    expected = true;
  };

  # module: explicit hand-written config wins over defaults
  test-stackdiscovery-module-overridden-by-handwritten = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
              component.module = {
                customValue = "from-defaults";
              };
            };
            stacks.networking.components.vpc.customValue = "from-handwritten";
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "networking"
            "components"
            "vpc"
            "customValue"
          ])
        ];
    expected = "from-handwritten";
  };

  # module: can declare typed options and set their values
  test-stackdiscovery-module-declares-option = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
              component.module =
                { config, lib, ... }:
                {
                  options.customFlag = lib.mkOption {
                    type = lib.types.bool;
                    default = false;
                  };
                  config.customFlag = lib.mkDefault true;
                };
            };
            # Hand-written assignment at normal priority overrides lib.mkDefault
            stacks.networking.components.vpc.customFlag = false;
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "networking"
            "components"
            "vpc"
            "customFlag"
          ])
        ];
    expected = false;
  };

  # module: multiple modules compose via deferredModule merging
  test-stackdiscovery-module-multiple-modules-compose = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
              component.module = {
                attrA = "from-first";
              };
            };
          }
          {
            stackDiscovery.component.module = {
              attrB = "from-second";
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "networking"
            "components"
            "vpc"
          ])
          (c: { inherit (c) attrA attrB; })
        ];
    expected = {
      attrA = "from-first";
      attrB = "from-second";
    };
  };

  # module: stack is set for discovered components
  test-stackdiscovery-module-stack-set = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeTree;
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "networking"
            "components"
            "vpc"
            "stack"
          ])
        ];
    expected = "networking";
  };

  # Regression: component.nix setting one deployment key used to discard
  # every other filesystem-discovered deployment key entirely, because the
  # discovered defaults were wrapped in an outer `mkDefault` covering the
  # whole `deployments` attrset. Any unmarked `deployments` definition from
  # component.nix then won at the whole-option level, before the attrsOf
  # per-key merge ever ran. Only "dev" is set in fixtures/deployments-merge's
  # component.nix; "prod" must still be discovered.
  test-stackdiscovery-component-nix-partial-deployments-override-keeps-other-keys = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeDeploymentsMerge;
              stackName = "deployments-merge";
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "deployments-merge_svc_dev"
      "deployments-merge_svc_prod"
    ];
  };

  # Same fixture: the field set on "dev" in component.nix must still apply,
  # and "prod" must keep its filesystem-derived default (no branchDeploy,
  # environment = "prod").
  test-stackdiscovery-component-nix-partial-deployments-override-applies-fields = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stackDiscovery = {
              enable = true;
              path = fakeDeploymentsMerge;
              stackName = "deployments-merge";
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "stacks"
            "deployments-merge"
            "components"
            "svc"
            "deployments"
          ])
          (deployments: {
            dev = {
              inherit (deployments.dev) branchDeploy environment;
            };
            prod = { inherit (deployments.prod) environment; };
          })
        ];
    expected = {
      dev = {
        branchDeploy = true;
        environment = "dev";
      };
      prod = {
        environment = "prod";
      };
    };
  };
}
