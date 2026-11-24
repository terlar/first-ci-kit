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

  test-process-compose-steps-block-env-raw = {
    expr = test-lib.eval-process-compose {
      stepBlocks.greet = {
        inputs.who.default = "world";
        steps = { inputs }: [ { run = "echo ${inputs.who}"; } ];
      };
      jobs.job1.steps = [
        {
          block = "greet";
          inputs.who = "pc";
        }
        {
          run = "echo $X";
          env.X = "1";
        }
        { github-actions.uses = "x/y@v1"; }
        { gitlab-ci = [ "gl" ]; }
      ];
    };
    expected = {
      processes.job1 = {
        command = "echo pc\n( export X=\"1\"\necho $X\n)\ngl";
      };
    };
  };
}
