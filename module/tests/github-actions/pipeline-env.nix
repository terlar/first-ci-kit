{ test-lib, ... }:

{
  # Pipeline-level env is emitted as workflow-level env: in GitHub Actions.
  test-github-actions-pipeline-env = {
    expr = test-lib.eval-github-actions {
      env = {
        NIX_CACHE_URL = "s3://example-cache";
        LOG_LEVEL = "debug";
      };
      jobs.job1.commands = [ "make test" ];
    };
    expected = {
      env = {
        NIX_CACHE_URL = "s3://example-cache";
        LOG_LEVEL = "debug";
      };
      jobs.job1 = {
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "make test"; }
        ];
      };
    };
  };

  # github-actions.settings.env takes precedence over pipeline-level env for
  # the same key.
  test-github-actions-pipeline-env-backend-override = {
    expr = test-lib.eval-github-actions {
      env.LOG_LEVEL = "debug";
      github-actions.settings.env.LOG_LEVEL = "info";
      jobs.job1.commands = [ "make test" ];
    };
    expected = {
      env.LOG_LEVEL = "info";
      jobs.job1 = {
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "make test"; }
        ];
      };
    };
  };
}
