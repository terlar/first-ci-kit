{ lib, test-lib, ... }:

{
  test-github-actions-job-artifacts-upload = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          paths = [ ".ci/terraform/*" ];
          retentionDays = 7;
        };
      };
    };
    expected = {
      jobs.plan = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "tf-plan svc dev"; }
          {
            uses = "actions/upload-artifact@v7";
            "with" = {
              name = "svc-dev-plan";
              path = ".ci/terraform/*";
              retention-days = 7;
            };
          }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-download = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        commands = [ "tf-deploy svc dev" ];
        artifacts.download = {
          name = "svc-dev-plan";
        };
      };
    };
    expected = {
      jobs.deploy = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "actions/download-artifact@v8";
            "with".name = "svc-dev-plan";
          }
          { run = "tf-deploy svc dev"; }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-download-with-path = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        commands = [ "tf-deploy svc dev" ];
        artifacts.download = {
          name = "svc-dev-plan";
          path = ".ci/terraform";
        };
      };
    };
    expected = {
      jobs.deploy = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "actions/download-artifact@v8";
            "with" = {
              name = "svc-dev-plan";
              path = ".ci/terraform";
            };
          }
          { run = "tf-deploy svc dev"; }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-custom-upload-action = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        uploadArtifactAction = "actions/upload-artifact@v3";
      };
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          paths = [ ".ci/terraform/*" ];
        };
      };
    };
    expected = {
      jobs.plan = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "tf-plan svc dev"; }
          {
            uses = "actions/upload-artifact@v3";
            "with" = {
              name = "svc-dev-plan";
              path = ".ci/terraform/*";
            };
          }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-custom-download-action = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        downloadArtifactAction = "actions/download-artifact@v3";
      };
      jobs.deploy = {
        commands = [ "tf-deploy svc dev" ];
        artifacts.download = {
          name = "svc-dev-plan";
        };
      };
    };
    expected = {
      jobs.deploy = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "actions/download-artifact@v3";
            "with".name = "svc-dev-plan";
          }
          { run = "tf-deploy svc dev"; }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-upload-env-path = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.plan = {
        env = {
          STACK = "networking";
          COMPONENT = "vpc";
        };
        commands = [ "tofu plan" ];
        artifacts.upload = {
          name = "plan-artifact";
          paths = [
            "terraform/$STACK/$COMPONENT/tfplan"
            "terraform/\${STACK}/\${COMPONENT}/tfplan"
          ];
          retentionDays = 7;
        };
      };
    };
    expected = {
      jobs.plan = {
        runs-on = "ubuntu-latest";
        env = {
          STACK = "networking";
          COMPONENT = "vpc";
        };
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "tofu plan"; }
          {
            uses = "actions/upload-artifact@v7";
            "with" = {
              name = "plan-artifact";
              path = "terraform/\${{ env.STACK }}/\${{ env.COMPONENT }}/tfplan\nterraform/\${{ env.STACK }}/\${{ env.COMPONENT }}/tfplan";
              retention-days = 7;
            };
          }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-upload-env-path-prefix-shadowing = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.plan = {
        env = {
          STACK = "networking";
          STACK_REGION = "eu-west-1";
        };
        commands = [ "tofu plan" ];
        artifacts.upload = {
          name = "plan-artifact";
          paths = [ "terraform/$STACK_REGION/$STACK/tfplan" ];
        };
      };
    };
    expected = {
      jobs.plan = {
        runs-on = "ubuntu-latest";
        env = {
          STACK = "networking";
          STACK_REGION = "eu-west-1";
        };
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "tofu plan"; }
          {
            uses = "actions/upload-artifact@v7";
            "with" = {
              name = "plan-artifact";
              path = "terraform/\${{ env.STACK_REGION }}/\${{ env.STACK }}/tfplan";
            };
          }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-download-env-path = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        env.STACK = "networking";
        commands = [ "tofu apply" ];
        artifacts.download = {
          name = "plan-artifact";
          path = "terraform/$STACK";
        };
      };
    };
    expected = {
      jobs.deploy = {
        runs-on = "ubuntu-latest";
        env.STACK = "networking";
        steps = [
          { uses = "actions/checkout@v7"; }
          {
            uses = "actions/download-artifact@v8";
            "with" = {
              name = "plan-artifact";
              path = "terraform/\${{ env.STACK }}";
            };
          }
          { run = "tofu apply"; }
        ];
      };
    };
  };

  test-github-actions-job-artifacts-upload-workflow-env-path = {
    expr =
      lib.pipe
        {
          github-actions.defaultRunsOn = "ubuntu-latest";
          inputs.stack.description = "Stack name";
          inputs.component.description = "Component name";
          jobs.plan = {
            commands = [ "tofu plan" ];
            artifacts.upload = {
              name = "plan-artifact";
              paths = [ "terraform/$STACK/$COMPONENT/tfplan" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.plan.steps)
        ];
    expected = [
      { uses = "actions/checkout@v7"; }
      { run = "tofu plan"; }
      {
        uses = "actions/upload-artifact@v7";
        "with" = {
          name = "plan-artifact";
          path = "terraform/\${{ env.STACK }}/\${{ env.COMPONENT }}/tfplan";
        };
      }
    ];
  };

  test-github-actions-job-artifacts-upload-global-env-path = {
    expr =
      lib.pipe
        {
          github-actions = {
            defaultRunsOn = "ubuntu-latest";
            settings.env.STACK = "networking";
          };
          jobs.plan = {
            commands = [ "tofu plan" ];
            artifacts.upload = {
              name = "plan-artifact";
              paths = [ "terraform/$STACK/tfplan" ];
            };
          };
        }
        [
          test-lib.evalConfig
          (cfg: cfg.github-actions.settings.jobs.plan.steps)
        ];
    expected = [
      { uses = "actions/checkout@v7"; }
      { run = "tofu plan"; }
      {
        uses = "actions/upload-artifact@v7";
        "with" = {
          name = "plan-artifact";
          path = "terraform/\${{ env.STACK }}/tfplan";
        };
      }
    ];
  };
}
