{ test-lib, ... }:

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
          { uses = "actions/checkout@v6"; }
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
          { uses = "actions/checkout@v6"; }
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
          { uses = "actions/checkout@v6"; }
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
          { uses = "actions/checkout@v6"; }
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
          { uses = "actions/checkout@v6"; }
          {
            uses = "actions/download-artifact@v3";
            "with".name = "svc-dev-plan";
          }
          { run = "tf-deploy svc dev"; }
        ];
      };
    };
  };
}
