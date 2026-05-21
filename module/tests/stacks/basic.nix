{ lib, test-lib, ... }:

let
  tofuFactory =
    {
      stackName,
      componentName,
      deployment,
      needs,
      formatJobName,
      ...
    }:
    let
      jobName = formatJobName [
        stackName
        componentName
        deployment
      ];
    in
    {
      jobs.${jobName} = {
        pipelineCall = {
          pipeline = "infra-pipeline";
          gitlab-ci = {
            templatePath = "ci/templates/infra.yml";
            rulesInput = "rules";
          };
        };
        tags = [
          (formatJobName [
            stackName
            deployment
          ])
          jobName
        ];
        branches.default = {
          triggers.onPush = true;
          triggers.onMergeRequest = true;
          changes.paths = [ "stacks/${stackName}/${componentName}/${deployment}/**" ];
        };
      };
      jobSets = {
        ${formatJobName [ deployment ]}.tags = [ deployment ];
        ${
          formatJobName [
            stackName
            deployment
          ]
        }.tags =
          [
            (formatJobName [
              stackName
              deployment
            ])
          ];
        ${jobName} = {
          tags = [ jobName ];
          inherit needs;
        };
      };
    };

  baseConfig = {
    defaultJobFactory = "tofu";
    pipelines.infra-pipeline = {
      gitlab-ci.asComponent = true;
      gitlab-ci.templatePath = "ci/templates/infra.yml";
      jobs.apply.commands = [ "tofu apply" ];
    };
    jobFactories.tofu.fn = tofuFactory;
  };
in

{
  # 1. Basic topology: 2 components × 2 deployments → correct jobs and jobSets
  test-stacks-basic-topology-jobs = {
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
                api = { };
                worker = { };
              };
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") builtins.attrNames ];
    expected = [
      "app_api_dev"
      "app_api_prod"
      "app_worker_dev"
      "app_worker_prod"
    ];
  };

  test-stacks-basic-topology-jobsets = {
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
                api = { };
                worker = { };
              };
            };
          }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobSets") builtins.attrNames ];
    expected = [
      "app_api_dev"
      "app_api_prod"
      "app_dev"
      "app_prod"
      "app_worker_dev"
      "app_worker_prod"
      "dev"
      "prod"
    ];
  };

  test-stacks-job-tags = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobs"
            "app_api_dev"
            "tags"
          ])
        ];
    expected = [
      "app_dev"
      "app_api_dev"
    ];
  };

  test-stacks-jobset-tags = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api = { };
            };
          }
        ]
        [
          test-lib.evalConfig
          (cfg: {
            inherit (cfg.jobSets.dev) tags;
            app_dev = cfg.jobSets.app_dev.tags;
            app_api_dev = cfg.jobSets.app_api_dev.tags;
          })
        ];
    expected = {
      tags = [ "dev" ];
      app_dev = [ "app_dev" ];
      app_api_dev = [ "app_api_dev" ];
    };
  };

  # 2. needs resolution
  test-stacks-needs-same-stack-all-components = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components = {
                db = { };
                api.needs = [
                  {
                    component = null;
                    stack = null;
                  }
                ];
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobSets"
            "app_api_dev"
            "needs"
          ])
        ];
    expected = [ { jobSet = "app_dev"; } ];
  };

  test-stacks-needs-same-stack-specific-component = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components = {
                db = { };
                api.needs = [ { component = "db"; } ];
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobSets"
            "app_api_dev"
            "needs"
          ])
        ];
    expected = [ { jobSet = "app_db_dev"; } ];
  };

  test-stacks-needs-cross-stack = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks = {
              networking = {
                deployments.dev = { };
                components.vpc = { };
              };
              cluster = {
                deployments.dev = { };
                components."control-plane".needs = [
                  {
                    stack = "networking";
                    component = "vpc";
                  }
                ];
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobSets"
            "cluster_control-plane_dev"
            "needs"
          ])
        ];
    expected = [ { jobSet = "networking_vpc_dev"; } ];
  };

  test-stacks-needs-cross-stack-all-components = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks = {
              networking = {
                deployments.dev = { };
                components.vpc = { };
              };
              app = {
                deployments.dev = { };
                components.api.needs = [ { stack = "networking"; } ];
              };
            };
          }
        ]
        [
          test-lib.evalConfig
          (lib.getAttrFromPath [
            "jobSets"
            "app_api_dev"
            "needs"
          ])
        ];
    expected = [ { jobSet = "networking_dev"; } ];
  };

  # 3. Empty stacks
  test-stacks-empty-generates-nothing = {
    expr =
      lib.pipe
        [
          baseConfig
          { stacks = { }; }
        ]
        [ test-lib.evalConfig (lib.getAttr "jobs") ];
    expected = { };
  };

  # 4. GitLab CI output
  test-stacks-gitlab-ci = {
    expr =
      lib.pipe
        [
          baseConfig
          {
            stacks.app = {
              deployments.dev = { };
              components.api = { };
            };
          }
        ]
        [ test-lib.eval-gitlab-ci ];
    expected = {
      include = [
        {
          local = "ci/templates/infra.yml";
          inputs.rules = [
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "stacks/app/api/dev/**" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "stacks/app/api/dev/**" ];
            }
          ];
        }
      ];
    };
  };
}
