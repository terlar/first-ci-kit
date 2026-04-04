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
          { uses = "actions/checkout@v6"; }
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
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job_b = {
          needs = [ "job_a" ];
          steps = [ { uses = "actions/checkout@v6"; } ];
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
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-c = {
          needs = [ "job-a" ];
          steps = [ { uses = "actions/checkout@v6"; } ];
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
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [ "job-a" ];
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
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

  test-github-actions-job-with-default-branch-trigger-onMergeRequest-with-paths = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        job-a = {
          branches.default = {
            changes.paths = [
              "config/**"
              "terraform/**"
            ];
            triggers.onMergeRequest = true;
          };
        };
        job-b = {
          branches.default = {
            triggers.onMergeRequest = true;
          };
        };
      };
    };

    expected = {
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            {
              id = "diff";
              shell = "bash";
              env.PATHS = "job-a:config/**\\|terraform/**";
              run = builtins.readFile ../../jobs/github-actions/diff-script;
            }
          ];
        };

        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
          ];
        };

        job-b = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
          ];
        };
      };
    };
  };

  test-github-actions-job-custom-checkout-action = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
      # renovate:ignore
      pipeline.github-actions.checkoutAction = "actions/checkout@v5.0.1";
      jobs.job1 = {
        checkout = true;
        commands = [ "echo hello" ];
      };
    };
    expected = {
      jobs.job1 = {
        runs-on = "ubuntu-latest";
        steps = [
          # renovate:ignore
          { uses = "actions/checkout@v5.0.1"; }
          { run = "echo hello"; }
        ];
      };
    };
  };

  test-github-actions-changes-job-uses-custom-checkout-action = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
      # renovate:ignore
      pipeline.github-actions.checkoutAction = "actions/checkout@v5.0.1";
      jobs = {
        job-a = {
          branches.default = {
            changes.paths = [ "src/**" ];
            triggers.onMergeRequest = true;
          };
        };
      };
    };
    expected = {
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            # renovate:ignore
            { uses = "actions/checkout@v5.0.1"; }
            {
              id = "diff";
              shell = "bash";
              env.PATHS = "job-a:src/**";
              run = builtins.readFile ../../jobs/github-actions/diff-script;
            }
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            # renovate:ignore
            { uses = "actions/checkout@v5.0.1"; }
          ];
        };
      };
    };
  };
}
