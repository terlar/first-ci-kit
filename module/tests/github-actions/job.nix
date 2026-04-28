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
          { uses = "actions/checkout@v6"; }
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

  test-github-actions-job-with-default-branch-trigger-onMergeRequest-with-paths = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";

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
                DIFF_PATHS = "job-a:config/**|terraform/**";
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

  test-github-actions-changes-job-uses-custom-checkout-action = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      github-actions.checkoutAction = "actions/checkout@v5";
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
          "if" =
            ''''${{ always() && (needs.job-a.result == 'success' || needs.job-a.result == 'skipped') }}'';
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-optional-need = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
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
            ''''${{ always() && fromJSON(needs.changes.outputs.changes)['job-b'] == true && (needs.job-a.result == 'success' || needs.job-a.result == 'skipped') }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-non-optional-need = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
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
            { uses = "actions/checkout@v6"; }
            { run = "echo job-a"; }
          ];
        };
      };
    };
  };

  test-github-actions-job-artifact-upload = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          paths = [ ".ci/terraform/*" ];
          retentionDays = 7;
        };
      };
    };
    expected = {
      jobs.plan = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "tf-plan svc dev"; }
          {
            uses = "actions/upload-artifact@v7";
            "with" = {
              name = "svc-dev-plan";
              path = ".ci/terraform/*";
              retention-days = 7;
            };
          }
        ];
      };
    };
  };

  test-github-actions-job-artifact-download = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        commands = [ "tf-deploy svc dev" ];
        artifacts.download = {
          name = "svc-dev-plan";
        };
      };
    };
    expected = {
      jobs.deploy = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          {
            uses = "actions/download-artifact@v8";
            "with".name = "svc-dev-plan";
          }
          { run = "tf-deploy svc dev"; }
        ];
      };
    };
  };

  test-github-actions-job-artifact-custom-upload-action = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        uploadArtifactAction = "actions/upload-artifact@v3";
      };
      jobs.plan = {
        commands = [ "tf-plan svc dev" ];
        artifacts.upload = {
          name = "svc-dev-plan";
          paths = [ ".ci/terraform/*" ];
        };
      };
    };
    expected = {
      jobs.plan = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "tf-plan svc dev"; }
          {
            uses = "actions/upload-artifact@v3";
            "with" = {
              name = "svc-dev-plan";
              path = ".ci/terraform/*";
            };
          }
        ];
      };
    };
  };

  test-github-actions-job-caller-basic = {
    expr = test-lib.eval-github-actions {
      jobs.deploy = {
        github-actions = {
          uses = "./.github/workflows/profile-deploy.yml";
          secrets = "inherit";
          "with".service = "my-service";
        };
      };
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/profile-deploy.yml";
        secrets = "inherit";
        "with".service = "my-service";
      };
    };
  };

  test-github-actions-job-caller-with-changes = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        branches.default = {
          changes.paths = [ "src/**" ];
          triggers.onMergeRequest = true;
        };
        github-actions = {
          uses = "./.github/workflows/profile-deploy.yml";
          "with".service = "my-service";
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
                DIFF_PATHS = "deploy:src/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        deploy = {
          uses = "./.github/workflows/profile-deploy.yml";
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['deploy'] == true }}'';
          "with".service = "my-service";
        };
      };
    };
  };

  test-github-actions-job-with-changes-and-colon-in-name = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      };
      jobs."org:svc-a" = {
        branches.default = {
          changes.paths = [ "src/**" ];
          triggers.onMergeRequest = true;
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
                DIFF_PATHS = "org_svc-a:src/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        org_svc-a = {
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['org_svc-a'] == true }}'';
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
      };
    };
  };

  test-github-actions-job-artifact-custom-download-action = {
    expr = test-lib.eval-github-actions {
      github-actions = {
        defaultRunsOn = "ubuntu-latest";
        downloadArtifactAction = "actions/download-artifact@v3";
      };
      jobs.deploy = {
        commands = [ "tf-deploy svc dev" ];
        artifacts.download = {
          name = "svc-dev-plan";
        };
      };
    };
    expected = {
      jobs.deploy = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          {
            uses = "actions/download-artifact@v3";
            "with".name = "svc-dev-plan";
          }
          { run = "tf-deploy svc dev"; }
        ];
      };
    };
  };
}
