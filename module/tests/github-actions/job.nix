{ test-lib, ... }:

{
  test-github-actions-job-basic = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job1 = {
        checkout = true;
        commands = [ "echo 'Run your script here'" ];
      };
    };
    expected = {
      jobs.job1 = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v4"; }
          { run = "echo 'Run your script here'"; }
        ];
      };
    };
  };

  test-github-actions-job-transform-name = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      jobs = {
        "job:a" = { };
        "job:b".needs = [
          { job = "job:a"; }
        ];
      };
    };
    expected = {
      jobs = {
        job_a = {
          steps = [ { uses = "actions/checkout@v4"; } ];
        };
        job_b = {
          needs = [ "job_a" ];
          steps = [ { uses = "actions/checkout@v4"; } ];
        };
      };
    };
  };

  test-github-actions-job-enable = {
    expr = test-lib.eval-github-actions {
      jobs = {
        job-a = { };
        job-b.enable = false;
        job-c.needs = [
          { job = "job-a"; }
          { job = "job-b"; }
        ];
      };
    };
    expected = {
      jobs = {
        job-a = {
          steps = [ { uses = "actions/checkout@v4"; } ];
        };
        job-c = {
          needs = [ "job-a" ];
          steps = [ { uses = "actions/checkout@v4"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-needs = {
    expr = test-lib.eval-github-actions {
      jobs.job-a = { };
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };
    expected = {
      jobs = {
        job-a = {
          steps = [ { uses = "actions/checkout@v4"; } ];
        };
        job-b = {
          needs = [ "job-a" ];
          steps = [ { uses = "actions/checkout@v4"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-self-needs = {
    expr = test-lib.eval-github-actions {
      jobs.job-a.needs = [ { job = "job-a"; } ];
    };

    expected = {
      jobs.job-a.steps = [ { uses = "actions/checkout@v4"; } ];
    };
  };
}
