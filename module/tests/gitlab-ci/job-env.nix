{ test-lib, ... }:

{
  # env is emitted as job-level variables: in GitLab CI.
  test-gitlab-ci-job-env = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job1 = {
        commands = [ "make test" ];
        env = {
          LOG_LEVEL = "debug";
          CONFIG_FILE = "config.json";
        };
      };
    };
    expected = {
      job1 = {
        script = [ "make test" ];
        variables = {
          LOG_LEVEL = "debug";
          CONFIG_FILE = "config.json";
        };
      };
    };
  };

  # gitlab-ci.variables takes precedence over job-level env for the same key.
  test-gitlab-ci-job-env-backend-override = {
    expr = test-lib.eval-gitlab-ci {
      jobs.job1 = {
        commands = [ "make test" ];
        env.LOG_LEVEL = "debug";
        gitlab-ci.variables.LOG_LEVEL = "info";
      };
    };
    expected = {
      job1 = {
        script = [ "make test" ];
        variables.LOG_LEVEL = "info";
      };
    };
  };
}
