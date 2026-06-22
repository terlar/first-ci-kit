{ test-lib, ... }:

{
  test-github-actions-job-basic = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job1 = {
        checkout = true;
        commands = [ "echo 'Run your script here'" ];
      };
    };
    expected = {
      jobs.job1 = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v7"; }
          { run = "echo 'Run your script here'"; }
        ];
      };
    };
  };

  test-github-actions-job-transform-name = {
    expr = test-lib.eval-github-actions {
      github-actions.transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
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
          steps = [ { uses = "actions/checkout@v7"; } ];
        };
        job_b = {
          needs = [ "job_a" ];
          steps = [ { uses = "actions/checkout@v7"; } ];
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
          steps = [ { uses = "actions/checkout@v7"; } ];
        };
        job-c = {
          needs = [ "job-a" ];
          steps = [ { uses = "actions/checkout@v7"; } ];
        };
      };
    };
  };

  test-github-actions-job-per-backend-disable = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = {
          commands = [ "echo job-a" ];
        };
        job-b = {
          commands = [ "echo job-b" ];
          github-actions.enable = false;
        };
        job-c = {
          commands = [ "echo job-c" ];
          needs = [ { job = "job-b"; } ];
        };
      };
    };
    expected = {
      jobs = {
        job-a = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v7"; }
            { run = "echo job-a"; }
          ];
        };
        job-c = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v7"; }
            { run = "echo job-c"; }
          ];
        };
      };
    };
  };

  test-github-actions-job-global-disable-overrides-per-backend-enable = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = {
          commands = [ "echo job-a" ];
        };
        job-b = {
          commands = [ "echo job-b" ];
          enable = false;
          github-actions.enable = true;
        };
      };
    };
    expected = {
      jobs = {
        job-a = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v7"; }
            { run = "echo job-a"; }
          ];
        };
      };
    };
  };

  # fetchDepth = 0 on a job adds with.fetch-depth = 0 to the checkout step.
  test-github-actions-job-fetch-depth = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job1 = {
        fetchDepth = 0;
        commands = [ "git log" ];
      };
    };
    expected = {
      jobs.job1 = {
        runs-on = "ubuntu-latest";
        steps = [
          {
            uses = "actions/checkout@v7";
            "with"."fetch-depth" = 0;
          }
          { run = "git log"; }
        ];
      };
    };
  };

  test-github-actions-job-custom-checkout-action = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      github-actions.checkoutAction = "actions/checkout@v5";
      jobs.job1 = {
        checkout = true;
        commands = [ "echo hello" ];
      };
    };
    expected = {
      jobs.job1 = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v5"; }
          { run = "echo hello"; }
        ];
      };
    };
  };

  # fetchDepth = null (default) omits the with block entirely.
  test-github-actions-job-fetch-depth-null-omits-with = {
    expr = test-lib.eval-github-actions {
      jobs.job1.commands = [ "echo hi" ];
    };
    expected = {
      jobs.job1.steps = [
        { uses = "actions/checkout@v7"; }
        { run = "echo hi"; }
      ];
    };
  };
}
