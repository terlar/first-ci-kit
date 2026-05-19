{ test-lib, ... }:

{
  test-gitlab-ci-job-pipeline-call-basic-no-inputs-key = {
    expr =
      (test-lib.eval-gitlab-ci {
        pipelines.my-pipeline = {
          gitlab-ci.asComponent = true;
          gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
          jobs.do-thing.commands = [ "echo hello" ];
        };
        jobs.deploy.pipelineCall.pipeline = "my-pipeline";
      }).include;
    # A basic pipeline call with no inputs should produce no `inputs` key in the include entry.
    expected = [ { local = "ci/templates/my-pipeline.yml"; } ];
  };

  test-gitlab-ci-job-pipeline-call-basic = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      include = [ { local = "ci/templates/my-pipeline.yml"; } ];
    };
  };

  test-gitlab-ci-job-pipeline-call-with-inputs = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs = {
          environment = "prod";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.environment = "prod";
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-job-suppressed = {
    expr =
      (test-lib.eval-gitlab-ci {
        pipelines.my-pipeline = {
          gitlab-ci.asComponent = true;
          gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
          jobs.do-thing.commands = [ "echo hello" ];
        };
        jobs.deploy.pipelineCall.pipeline = "my-pipeline";
      }) ? deploy;
    expected = false;
  };

  test-gitlab-ci-job-pipeline-call-gha-extra-inputs-not-in-gitlab = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        github-actions.extraInputs.ref = "main";
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.environment = "prod";
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-gitlab-extra-inputs-merged = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        gitlab-ci.extraInputs.plan_needs = "tf-plan";
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            environment = "prod";
            plan_needs = "tf-plan";
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-gitlab-extra-inputs-list-of-strings = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        gitlab-ci.extraInputs.plan_needs = [
          "network:dev:deploy"
          "dns:dev:deploy"
        ];
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            environment = "prod";
            plan_needs = [
              "network:dev:deploy"
              "dns:dev:deploy"
            ];
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-gitlab-extra-inputs-list-of-attrs = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        gitlab-ci.extraInputs.plan_needs = [
          {
            job = "network:dev:deploy";
            optional = true;
          }
          {
            job = "dns:dev:deploy";
            optional = true;
          }
        ];
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            environment = "prod";
            plan_needs = [
              {
                artifacts = true;
                job = "network:dev:deploy";
                optional = true;
              }
              {
                artifacts = true;
                job = "dns:dev:deploy";
                optional = true;
              }
            ];
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-per-job-template-path-overrides-pipeline = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        gitlab-ci.templatePath = "ci/override/template.yml";
      };
    };
    expected = {
      include = [ { local = "ci/override/template.yml"; } ];
    };
  };

  test-gitlab-ci-job-pipeline-call-per-job-template-path-no-pipeline-path = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        gitlab-ci.templatePath = "ci/override/template.yml";
      };
    };
    expected = {
      include = [ { local = "ci/override/template.yml"; } ];
    };
  };

  # jobDefaults.gitlab-ci.rules appear in rulesInput
  test-gitlab-ci-job-pipeline-call-rules-input-includes-job-defaults-rules = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobSets.service = {
        jobs = [ "deploy" ];
        jobDefaults.gitlab-ci.rules = [
          {
            "if" = "$CI_PIPELINE_SOURCE == 'schedule'";
            when = "never";
          }
        ];
      };
      jobs.deploy = {
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.rulesInput = "rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.rules = [
            {
              "if" = "$CI_PIPELINE_SOURCE == 'schedule'";
              when = "never";
            }
          ];
        }
      ];
    };
  };

  # jobDefaults rules appear before branch trigger rules in rulesInput
  test-gitlab-ci-job-pipeline-call-rules-input-job-defaults-before-trigger-rules = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobSets.service = {
        jobs = [ "deploy" ];
        jobDefaults.gitlab-ci.rules = [
          {
            "if" = "$CI_PIPELINE_SOURCE == 'schedule' && $SCHEDULE_JOB != 'production-release-automation'";
            when = "never";
          }
          {
            "if" = ''$[[ inputs.pipeline ]] != "default"'';
            when = "never";
          }
        ];
      };
      jobs.deploy = {
        branches.default = {
          changes.paths = [ "src/" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.rulesInput = "rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.rules = [
            {
              "if" = "$CI_PIPELINE_SOURCE == 'schedule' && $SCHEDULE_JOB != 'production-release-automation'";
              when = "never";
            }
            {
              "if" = ''$[[ inputs.pipeline ]] != "default"'';
              when = "never";
            }
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "src/" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-rules-input-default-branch = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches.default = {
          changes.paths = [ "src/" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.rulesInput = "rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.rules = [
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "src/" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-push-rules-input-non-default-branch = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches = {
          default = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
          };
          production = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
            triggers.onPush = true;
          };
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.pushRulesInput = "deploy_rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.deploy_rules = [
            {
              "if" = "$CI_COMMIT_BRANCH == 'production'";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-rules-and-push-rules-inputs-combined = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches = {
          default = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
          };
          production = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
            triggers.onPush = true;
          };
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.rulesInput = "rules";
          gitlab-ci.pushRulesInput = "deploy_rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            rules = [
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
                changes = {
                  paths = [ "src/" ];
                  compare_to = "$CI_DEFAULT_BRANCH";
                };
              }
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == 'production'";
                changes = {
                  paths = [ "src/" ];
                  compare_to = "production";
                };
              }
              {
                "if" = "$CI_COMMIT_BRANCH == 'production'";
                changes.paths = [ "src/" ];
              }
            ];
            deploy_rules = [
              {
                "if" = "$CI_COMMIT_BRANCH == 'production'";
                changes.paths = [ "src/" ];
              }
            ];
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-all-rules-input = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches = {
          default = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
            triggers.onPush = true;
          };
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.allRulesInput = "plan_rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.plan_rules = [
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "src/" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "src/" ];
            }
          ];
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-all-rules-and-push-rules-inputs-combined = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches = {
          default = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
            triggers.onPush = true;
          };
          production = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
            triggers.onPush = true;
          };
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.allRulesInput = "plan_rules";
          gitlab-ci.pushRulesInput = "deploy_rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            plan_rules = [
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
                changes = {
                  paths = [ "src/" ];
                  compare_to = "$CI_DEFAULT_BRANCH";
                };
              }
              {
                "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
                changes.paths = [ "src/" ];
              }
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == 'production'";
                changes = {
                  paths = [ "src/" ];
                  compare_to = "production";
                };
              }
              {
                "if" = "$CI_COMMIT_BRANCH == 'production'";
                changes.paths = [ "src/" ];
              }
            ];
            deploy_rules = [
              {
                "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
                changes.paths = [ "src/" ];
              }
              {
                "if" = "$CI_COMMIT_BRANCH == 'production'";
                changes.paths = [ "src/" ];
              }
            ];
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-rules-and-all-rules-inputs-combined = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      jobs.deploy = {
        branches = {
          default = {
            changes.paths = [ "src/" ];
            triggers.onMergeRequest = true;
            triggers.onPush = true;
          };
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.rulesInput = "plan_rules";
          gitlab-ci.allRulesInput = "deploy_rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            plan_rules = [
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
                changes = {
                  paths = [ "src/" ];
                  compare_to = "$CI_DEFAULT_BRANCH";
                };
              }
              {
                "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
                changes.paths = [ "src/" ];
              }
            ];
            deploy_rules = [
              {
                "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
                changes = {
                  paths = [ "src/" ];
                  compare_to = "$CI_DEFAULT_BRANCH";
                };
              }
              {
                "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
                changes.paths = [ "src/" ];
              }
            ];
          };
        }
      ];
    };
  };

  test-gitlab-ci-job-pipeline-call-rules-input-inherits-trigger-paths = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci.asComponent = true;
        gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        jobs.do-thing.commands = [ "echo hello" ];
      };
      # infra job: a pipelineCall job whose paths we want to inherit
      jobs.infra = {
        branches.default = {
          changes.paths = [ "services/infra/**/*" ];
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.templatePath = "ci/templates/infra.yml";
        };
      };
      # post-deploy job: no own paths, only triggers
      jobs.deploy = {
        triggers = [ "infra" ];
        branches.default = {
          triggers.onMergeRequest = true;
          triggers.onPush = true;
        };
        pipelineCall = {
          pipeline = "my-pipeline";
          gitlab-ci.rulesInput = "rules";
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs.rules = [
            {
              "if" = "$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH";
              changes = {
                paths = [ "services/infra/**/*" ];
                compare_to = "$CI_DEFAULT_BRANCH";
              };
            }
            {
              "if" = "$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH";
              changes.paths = [ "services/infra/**/*" ];
            }
          ];
        }
        { local = "ci/templates/infra.yml"; }
      ];
    };
  };

  # github-actions.changes.enable must NOT leak changes/changes_key into GitLab CI spec.inputs.
  # Those inputs are GitHub Actions-only and must never be required by the GitLab component.
  test-gitlab-ci-pipeline-changes-enable-not-in-spec-inputs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipelines.my-pipeline = {
            github-actions.changes.enable = true;
            gitlab-ci.asComponent = true;
            gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
            inputs.stack.description = "Stack name";
            jobs.plan.commands = [ "tofu plan" ];
          };
        };
      in
      builtins.attrNames cfg.pipelines.my-pipeline.gitlab-ci.inputs;
    expected = [ "stack" ];
  };

  # needsInputs: single dependency pipelineCall job via jobSet
  test-gitlab-ci-job-pipeline-call-plan-needs-input-single = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci = {
          asComponent = true;
          templatePath = "ci/templates/my-pipeline.yml";
          transformJobName =
            name: "$[[ inputs.stack ]]_$[[ inputs.component ]]_$[[ inputs.deployment ]]_${name}";
        };
        jobs = {
          plan.commands = [ "tofu plan" ];
          deploy.commands = [ "tofu apply" ];
        };
      };
      jobSets.networking_dev = {
        jobs = [ "networking_vpc_dev" ];
      };
      jobSets.cluster_dev = {
        tags = [ "cluster_dev" ];
        needs = [ { jobSet = "networking_dev"; } ];
      };
      jobs.networking_vpc_dev = {
        tags = [ "cluster_dev" ];
        pipelineCall = {
          pipeline = "my-pipeline";
          inputs = {
            stack = "networking";
            component = "vpc";
            deployment = "dev";
          };
          gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        };
      };
      jobs.cluster_cp_dev = {
        tags = [ "cluster_dev" ];
        pipelineCall = {
          pipeline = "my-pipeline";
          inputs = {
            stack = "cluster";
            component = "cp";
            deployment = "dev";
          };
          gitlab-ci = {
            templatePath = "ci/templates/my-pipeline.yml";
            needsInputs = {
              "plan_needs" = "deploy";
            };
          };
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            stack = "cluster";
            component = "cp";
            deployment = "dev";
            plan_needs = [ "networking_vpc_dev_deploy" ];
          };
        }
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            stack = "networking";
            component = "vpc";
            deployment = "dev";
          };
        }
      ];
    };
  };

  # needsInputs: multiple dependency pipelineCall jobs via jobSet
  test-gitlab-ci-job-pipeline-call-plan-needs-input-multiple = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci = {
          asComponent = true;
          templatePath = "ci/templates/my-pipeline.yml";
          transformJobName =
            name: "$[[ inputs.stack ]]_$[[ inputs.component ]]_$[[ inputs.deployment ]]_${name}";
        };
        jobs = {
          plan.commands = [ "tofu plan" ];
          deploy.commands = [ "tofu apply" ];
        };
      };
      jobSets.networking_dev.jobs = [
        "networking_vpc_dev"
        "networking_dns_dev"
      ];
      jobs = {
        networking_vpc_dev.pipelineCall = {
          pipeline = "my-pipeline";
          inputs = {
            stack = "networking";
            component = "vpc";
            deployment = "dev";
          };
          gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        };
        networking_dns_dev.pipelineCall = {
          pipeline = "my-pipeline";
          inputs = {
            stack = "networking";
            component = "dns";
            deployment = "dev";
          };
          gitlab-ci.templatePath = "ci/templates/my-pipeline.yml";
        };
        cluster_cp_dev = {
          needs = [
            { job = "networking_vpc_dev"; }
            { job = "networking_dns_dev"; }
          ];
          pipelineCall = {
            pipeline = "my-pipeline";
            inputs = {
              stack = "cluster";
              component = "cp";
              deployment = "dev";
            };
            gitlab-ci = {
              templatePath = "ci/templates/my-pipeline.yml";
              needsInputs = {
                "plan_needs" = "deploy";
              };
            };
          };
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            stack = "cluster";
            component = "cp";
            deployment = "dev";
            plan_needs = [
              "networking_vpc_dev_deploy"
              "networking_dns_dev_deploy"
            ];
          };
        }
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            stack = "networking";
            component = "dns";
            deployment = "dev";
          };
        }
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            stack = "networking";
            component = "vpc";
            deployment = "dev";
          };
        }
      ];
    };
  };

  # needsInputs: omitted when no pipelineCall dependencies exist
  test-gitlab-ci-job-pipeline-call-plan-needs-input-omitted-when-no-deps = {
    expr = test-lib.eval-gitlab-ci {
      pipelines.my-pipeline = {
        gitlab-ci = {
          asComponent = true;
          templatePath = "ci/templates/my-pipeline.yml";
          transformJobName =
            name: "$[[ inputs.stack ]]_$[[ inputs.component ]]_$[[ inputs.deployment ]]_${name}";
        };
        jobs = {
          plan.commands = [ "tofu plan" ];
          deploy.commands = [ "tofu apply" ];
        };
      };
      jobs.networking_vpc_dev.pipelineCall = {
        pipeline = "my-pipeline";
        inputs = {
          stack = "networking";
          component = "vpc";
          deployment = "dev";
        };
        gitlab-ci = {
          templatePath = "ci/templates/my-pipeline.yml";
          needsInputs = {
            "plan_needs" = "deploy";
          };
        };
      };
    };
    expected = {
      include = [
        {
          local = "ci/templates/my-pipeline.yml";
          inputs = {
            stack = "networking";
            component = "vpc";
            deployment = "dev";
          };
        }
      ];
    };
  };
}
