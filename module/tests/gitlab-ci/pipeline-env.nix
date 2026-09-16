{ test-lib, ... }:

{
  # Pipeline-level env is emitted as pipeline-level variables: in GitLab CI.
  test-gitlab-ci-pipeline-env = {
    expr = test-lib.eval-gitlab-ci {
      env = {
        NIX_CACHE_URL = "s3://example-cache";
        LOG_LEVEL = "debug";
      };
      jobs.job1.commands = [ "make test" ];
    };
    expected = {
      variables = {
        NIX_CACHE_URL = "s3://example-cache";
        LOG_LEVEL = "debug";
      };
      job1 = {
        script = [ "make test" ];
      };
    };
  };

  # gitlab-ci.settings.variables takes precedence over pipeline-level env for
  # the same key.
  test-gitlab-ci-pipeline-env-backend-override = {
    expr = test-lib.eval-gitlab-ci {
      env.LOG_LEVEL = "debug";
      gitlab-ci.settings.variables.LOG_LEVEL = "info";
      jobs.job1.commands = [ "make test" ];
    };
    expected = {
      variables.LOG_LEVEL = "info";
      job1 = {
        script = [ "make test" ];
      };
    };
  };
}
