{ test-lib, ... }:

{
  # env is emitted as a job-level env: block in GitHub Actions.
  test-github-actions-job-env = {
    expr = test-lib.eval-github-actions {
      jobs.job1 = {
        commands = [ "make test" ];
        env = {
          LOG_LEVEL = "debug";
          CONFIG_FILE = "config.json";
        };
      };
    };
    expected = {
      jobs.job1 = {
        env = {
          LOG_LEVEL = "debug";
          CONFIG_FILE = "config.json";
        };
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "make test"; }
        ];
      };
    };
  };

  # github-actions.env takes precedence over job-level env for the same key.
  test-github-actions-job-env-backend-override = {
    expr = test-lib.eval-github-actions {
      jobs.job1 = {
        commands = [ "make test" ];
        env.LOG_LEVEL = "debug";
        github-actions.env.LOG_LEVEL = "info";
      };
    };
    expected = {
      jobs.job1 = {
        env.LOG_LEVEL = "info";
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "make test"; }
        ];
      };
    };
  };
}
