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
              env = {
                DIFF_PATHS = "job-a:config/**\\|terraform/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
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
      pipeline.github-actions.checkoutAction = "actions/checkout@v5";
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

  test-github-actions-changes-job-uses-custom-checkout-action = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
      pipeline.github-actions.checkoutAction = "actions/checkout@v5";
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
            { uses = "actions/checkout@v5"; }
            {
              id = "diff";
              shell = "bash";
              env = {
                DIFF_PATHS = "job-a:src/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        job-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v5"; }
          ];
        };
      };
    };
  };

  test-github-actions-job-per-backend-disable = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
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
            { uses = "actions/checkout@v6"; }
            { run = "echo job-a"; }
          ];
        };
        job-c = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "echo job-c"; }
          ];
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
          "if" = ''''${{ (needs.job-a.result == 'success' || needs.job-a.result == 'skipped') }}'';
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-optional-need = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = { };
        job-b = {
          branches.default.changes.paths = [ "src/**" ];
          needs = [
            {
              job = "job-a";
              optional = true;
            }
          ];
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
              env = {
                DIFF_PATHS = "job-b:src/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        job-a = {
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [
            "changes"
            "job-a"
          ];
          "if" =
            ''''${{ fromJSON(needs.changes.outputs.changes)['job-b'] == true && (needs.job-a.result == 'success' || needs.job-a.result == 'skipped') }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-non-optional-need = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
      jobs = {
        job-a = { };
        job-b = {
          branches.default.changes.paths = [ "src/**" ];
          needs = [
            {
              job = "job-a";
              optional = false;
            }
          ];
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
              env = {
                DIFF_PATHS = "job-b:src/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        job-a = {
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        job-b = {
          needs = [
            "changes"
            "job-a"
          ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['job-b'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-global-disable-overrides-per-backend-enable = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";
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
            { uses = "actions/checkout@v6"; }
            { run = "echo job-a"; }
          ];
        };
      };
    };
  };
}
