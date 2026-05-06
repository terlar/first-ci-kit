{ test-lib, ... }:

{
  test-gitlab-ci-job-artifacts-upload = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "main";
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          paths = [ ".ci/terraform/*" ];
          gitlab-ci = {
            expire_in = "1 week";
            reports = {
              terraform = ".ci/terraform/plan-summary.json";
            };
          };
        };
      };
    };
    expected = {
      "plan" = {
        stage = "main";
        script = [ "tf-plan svc dev" ];
        artifacts = {
          public = false;
          expire_in = "1 week";
          paths = [ ".ci/terraform/*" ];
          reports.terraform = ".ci/terraform/plan-summary.json";
        };
      };
    };
  };

  test-gitlab-ci-job-artifacts-upload-retention-days = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "main";
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
      "plan" = {
        stage = "main";
        script = [ "tf-plan svc dev" ];
        artifacts = {
          public = false;
          expire_in = "7 days";
          paths = [ ".ci/terraform/*" ];
        };
      };
    };
  };

  test-gitlab-ci-job-artifacts-upload-expire-in-overrides-retention-days = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "main";
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          paths = [ ".ci/terraform/*" ];
          retentionDays = 7;
          gitlab-ci.expire_in = "1 week";
        };
      };
    };
    expected = {
      "plan" = {
        stage = "main";
        script = [ "tf-plan svc dev" ];
        artifacts = {
          public = false;
          expire_in = "1 week";
          paths = [ ".ci/terraform/*" ];
        };
      };
    };
  };

  test-gitlab-ci-job-artifacts-upload-no-paths = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "main";
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          gitlab-ci.reports = {
            terraform = ".ci/terraform/plan-summary.json";
          };
        };
      };
    };
    expected = {
      "plan" = {
        stage = "main";
        script = [ "tf-plan svc dev" ];
        artifacts = {
          public = false;
          reports.terraform = ".ci/terraform/plan-summary.json";
        };
      };
    };
  };

  # In GitLab CI, artifact downloading is done via needs with artifacts: true.
  test-gitlab-ci-job-artifacts-download = {
    expr = test-lib.eval-gitlab-ci {
      gitlab-ci.defaultStage = "main";
      jobs = {
        plan = {
          commands = [ "tf-plan svc dev" ];
          artifacts.upload = {
            name = "svc-dev-plan";
            paths = [ ".ci/terraform/*" ];
          };
        };
        deploy = {
          commands = [ "tf-deploy svc dev" ];
          needs = [
            {
              job = "plan";
              artifacts = true;
            }
          ];
        };
      };
    };
    expected = {
      plan = {
        stage = "main";
        script = [ "tf-plan svc dev" ];
        artifacts = {
          public = false;
          paths = [ ".ci/terraform/*" ];
        };
      };
      deploy = {
        stage = "main";
        script = [ "tf-deploy svc dev" ];
        needs = [
          {
            job = "plan";
            artifacts = true;
            optional = false;
          }
        ];
      };
    };
  };
}
