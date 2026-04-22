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
}
