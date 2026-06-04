{ test-lib, ... }:

{
  # env is emitted as process-compose environment list.
  test-process-compose-job-env = {
    expr = test-lib.eval-process-compose {
      jobs.job1 = {
        commands = [ "make test" ];
        env = {
          CONFIG_FILE = "config.json";
          LOG_LEVEL = "debug";
        };
      };
    };
    expected = {
      processes.job1 = {
        command = "make test";
        environment = [
          "CONFIG_FILE=config.json"
          "LOG_LEVEL=debug"
        ];
      };
    };
  };
}
