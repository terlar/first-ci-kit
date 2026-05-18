{ test-lib, ... }:

{
  test-github-actions-job-with-needs = {
    expr = test-lib.eval-github-actions {
      jobs.job-a = { };
      jobs.job-b.needs = [ { job = "job-a"; } ];
    };
    expected = {
      jobs = {
        job-a = {
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [ "job-a" ];
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-external-needs = {
    expr = test-lib.eval-github-actions {
      jobs.job-a.needs = [ { job = "external-job"; } ];
    };
    expected = {
      jobs.job-a = {
        needs = [ "external-job" ];
        steps = [ { uses = "actions/checkout@v6"; } ];
      };
    };
  };

  test-github-actions-job-with-external-needs-and-transform = {
    expr = test-lib.eval-github-actions {
      github-actions.transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      jobs = {
        "job:a".needs = [
          { job = "job:b"; }
          { job = "external_job"; }
        ];
        "job:b" = { };
      };
    };
    expected = {
      jobs = {
        job_a = {
          needs = [
            "job_b"
            "external_job"
          ];
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job_b.steps = [ { uses = "actions/checkout@v6"; } ];
      };
    };
  };

  test-github-actions-job-with-self-needs = {
    expr = test-lib.eval-github-actions {
      jobs.job-a.needs = [ { job = "job-a"; } ];
    };

    expected = {
      jobs.job-a.steps = [ { uses = "actions/checkout@v6"; } ];
    };
  };

  test-github-actions-job-with-needs-jobset = {
    expr = test-lib.eval-github-actions {
      jobs.job-a = { };
      jobs.job-b.needs = [ { jobSet = "jobset-a"; } ];

      jobSets.jobset-a.jobs = [ "job-a" ];
    };

    expected = {
      jobs = {
        job-a.steps = [ { uses = "actions/checkout@v6"; } ];
        job-b = {
          steps = [ { uses = "actions/checkout@v6"; } ];
          needs = [ "job-a" ];
        };
      };
    };
  };

  test-github-actions-job-with-optional-need = {
    expr = test-lib.eval-github-actions {
      jobs.job-a = { };
      jobs.job-b.needs = [
        {
          job = "job-a";
          optional = true;
        }
      ];
    };
    expected = {
      jobs = {
        job-a = {
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [ "job-a" ];
          "if" =
            ''''${{ always() && (needs.job-a.result == 'success' || needs.job-a.result == 'skipped') }}'';
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-run-always = {
    expr = test-lib.eval-github-actions {
      jobs.job-a = { };
      jobs.job-b = {
        runAlways = true;
        needs = [ { job = "job-a"; } ];
      };
    };
    expected = {
      jobs = {
        job-a.steps = [ { uses = "actions/checkout@v6"; } ];
        job-b = {
          needs = [ "job-a" ];
          "if" = ''''${{ always() && needs.job-a.result != 'skipped' }}'';
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-run-always-no-needs = {
    expr = test-lib.eval-github-actions {
      jobs.job-a.runAlways = true;
    };
    expected = {
      jobs.job-a.steps = [ { uses = "actions/checkout@v6"; } ];
    };
  };

  # No changes.paths — trigger sets on.pull_request but no changes detection job is created.
  test-github-actions-job-with-default-branch-trigger-on-merge-request = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job.branches.default.triggers.onMergeRequest = true;
    };

    expected = {
      on.pull_request.branches = [ "main" ];
      jobs.job = {
        "if" = ''''${{ github.event_name == 'pull_request' }}'';
        runs-on = "ubuntu-latest";
        steps = [ { uses = "actions/checkout@v6"; } ];
      };
    };
  };

  # No changes.paths — trigger sets on.push but no changes detection job is created.
  test-github-actions-job-with-default-branch-trigger-on-push = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.job.branches.default.triggers.onPush = true;
    };

    expected = {
      on.push.branches = [ "main" ];
      jobs.job = {
        runs-on = "ubuntu-latest";
        steps = [ { uses = "actions/checkout@v6"; } ];
      };
    };
  };

  # Trigger job referencing a non-existent job is silently filtered from needs.
  test-github-actions-job-triggers-filter-unknown-job = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-b = {
          triggers = [ "non-existent-job" ];
          commands = [ "echo job-b" ];
        };
      };
    };
    expected = {
      jobs.job-b = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "echo job-b"; }
        ];
      };
    };
  };

  # Trigger job referencing a globally disabled job is filtered from needs.
  test-github-actions-job-triggers-filter-disabled-job = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = {
          enable = false;
          commands = [ "echo job-a" ];
        };
        job-b = {
          triggers = [ "job-a" ];
          commands = [ "echo job-b" ];
        };
      };
    };
    expected = {
      jobs.job-b = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "echo job-b"; }
        ];
      };
    };
  };

  # Trigger job referencing a per-backend disabled job is filtered from needs.
  test-github-actions-job-triggers-filter-per-backend-disabled-job = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = {
          github-actions.enable = false;
          commands = [ "echo job-a" ];
        };
        job-b = {
          triggers = [ "job-a" ];
          commands = [ "echo job-b" ];
        };
      };
    };
    expected = {
      jobs.job-b = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "echo job-b"; }
        ];
      };
    };
  };
}
