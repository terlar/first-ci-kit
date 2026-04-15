{ test-lib, ... }:

{
  test-gitlab-ci-inputs = {
    expr = test-lib.eval-gitlab-ci-documents {
      gitlab-ci.inputs = {
        website = { };
        user.default = "test-user";
        flags.default = "";
      };

      jobs.job1 = {
        checkout = true;
        commands = [ "echo 'Run your script here'" ];
      };
    };

    expected = [
      {
        spec.inputs = {
          website = { };
          user.default = "test-user";
          flags.default = "";
        };
      }
      {
        job1.script = [ "echo 'Run your script here'" ];
      }
    ];
  };

  test-gitlab-ci-without-inputs = {
    expr = test-lib.eval-gitlab-ci-documents {
      jobs.job1 = {
        checkout = true;
        commands = [ "echo 'Run your script here'" ];
      };
    };

    expected = [
      {
        job1.script = [ "echo 'Run your script here'" ];
      }
    ];
  };
}
