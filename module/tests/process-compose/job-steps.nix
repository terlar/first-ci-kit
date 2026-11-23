{ test-lib, ... }:

{
  test-process-compose-steps = {
    expr = test-lib.eval-process-compose {
      jobs.job1 = {
        steps = [
          {
            run = "a";
            name = "A";
          }
        ];
        commands = [ "b" ];
      };
    };
    expected = {
      processes.job1 = {
        command = "echo 'A'\na\nb";
      };
    };
  };
}
