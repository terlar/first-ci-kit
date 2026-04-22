{ test-lib, ... }:

{
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

  test-github-actions-job-pipeline-call-gitlab-extra-inputs-not-in-gha = {
    expr = test-lib.eval-github-actions {
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        gitlab-ci.extraInputs.plan_needs = "tf-plan";
      };
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/my-pipeline.yml";
        secrets = "inherit";
        "with".environment = "prod";
      };
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
}
