{ test-lib, ... }:

{
  # Opted-in job must NOT appear inline; caller workflow_call job must appear instead
  test-github-actions-reusable-workflow-jobs-not-in-caller = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        job-a = {
          tags = [ "myset" ];
          commands = [ "echo hello" ];
        };
      };

      jobSets.myset = {
        tags = [ "myset" ];
        github-actions.reusableWorkflow = true;
      };
    };
    # job-a must NOT be in settings.jobs; the caller job for myset must be
    expected = {
      jobs = {
        myset = {
          uses = "./.github/workflows/myset.yml";
          secrets = "inherit";
        };
      };
    };
  };

  # reusableWorkflowSettings should contain the job-set entry with the job inside
  test-github-actions-reusable-workflow-settings-populated = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

          jobs = {
            job-a = {
              tags = [ "myset" ];
              commands = [ "echo hello" ];
            };
          };

          jobSets.myset = {
            tags = [ "myset" ];
            github-actions.reusableWorkflow = true;
          };
        };
      in
      cfg.pipeline.github-actions.reusableWorkflowSettings;
    expected = {
      myset = {
        on.workflow_call = { };
        jobs.job-a = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "echo hello"; }
          ];
        };
      };
    };
  };

  # Cross-job-set needs: reusable set B needs reusable set A → caller job for B needs ["set-a"]
  test-github-actions-reusable-workflow-cross-jobset-needs = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        job-a.tags = [ "set-a" ];
        job-b.tags = [ "set-b" ];
      };

      jobSets = {
        set-a = {
          tags = [ "set-a" ];
          github-actions.reusableWorkflow = true;
        };
        set-b = {
          tags = [ "set-b" ];
          needs = [ { jobSet = "set-a"; } ];
          github-actions.reusableWorkflow = true;
        };
      };
    };
    expected = {
      jobs = {
        set-a = {
          uses = "./.github/workflows/set-a.yml";
          secrets = "inherit";
        };
        set-b = {
          uses = "./.github/workflows/set-b.yml";
          secrets = "inherit";
          needs = [ "set-a" ];
        };
      };
    };
  };

  # Non-reusable job-set whose jobs all live inside reusable workflows:
  # reusable set-c needs non-reusable "group" job-set, whose jobs belong to
  # set-a and set-b (both reusable). The caller must emit the reusable job-set
  # names, not the hidden individual job names (which would be invalid in ci.yaml).
  test-github-actions-reusable-workflow-non-reusable-set-with-reusable-jobs = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        job-a.tags = [ "set-a" ];
        job-b.tags = [ "set-b" ];
        job-c.tags = [ "set-c" ];
      };

      jobSets = {
        # "group" is NOT reusable, but its jobs (job-a, job-b) belong to reusable sets
        group.tags = [
          "set-a"
          "set-b"
        ];
        set-a = {
          tags = [ "set-a" ];
          github-actions.reusableWorkflow = true;
        };
        set-b = {
          tags = [ "set-b" ];
          github-actions.reusableWorkflow = true;
        };
        set-c = {
          tags = [ "set-c" ];
          needs = [ { jobSet = "group"; } ];
          github-actions.reusableWorkflow = true;
        };
      };
    };
    # set-c caller must depend on set-a and set-b (the reusable sets that contain
    # group's jobs), not on the individual job names job-a / job-b
    expected = {
      jobs = {
        set-a = {
          uses = "./.github/workflows/set-a.yml";
          secrets = "inherit";
        };
        set-b = {
          uses = "./.github/workflows/set-b.yml";
          secrets = "inherit";
        };
        set-c = {
          uses = "./.github/workflows/set-c.yml";
          secrets = "inherit";
          needs = [
            "set-a"
            "set-b"
          ];
        };
      };
    };
  };

  # Non-opted-in job-sets continue to inline their jobs as before (no regression)
  test-github-actions-reusable-workflow-inline-jobs-unchanged = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        job-a.tags = [ "inline-set" ];
      };

      jobSets.inline-set = {
        tags = [ "inline-set" ];
        # github-actions.reusableWorkflow defaults to false
      };
    };
    expected = {
      jobs.job-a = {
        runs-on = "ubuntu-latest";
        steps = [ { uses = "actions/checkout@v6"; } ];
      };
    };
  };

  # Reusable workflow with jobs that have changes.paths gets a changes job inside
  test-github-actions-reusable-workflow-with-changes = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

          jobs = {
            job-a = {
              tags = [ "myset" ];
              commands = [ "echo hello" ];
              branches.default.changes.paths = [ "src/**" ];
            };
          };

          jobSets.myset = {
            tags = [ "myset" ];
            github-actions.reusableWorkflow = true;
          };
        };
      in
      cfg.pipeline.github-actions.reusableWorkflowSettings;
    expected = {
      myset = {
        on.workflow_call = { };
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
              { uses = "actions/checkout@v6"; }
              { run = "echo hello"; }
            ];
          };
        };
      };
    };
  };

  # Inline job dependencies of reusable job-set jobs surface at the caller level:
  # if a job inside a reusable workflow needs an inline job (not in any reusable
  # job-set), the caller workflow_call job must wait for it via `needs`.
  test-github-actions-reusable-workflow-inline-dep-in-caller-needs = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        validate.commands = [ "echo validate" ];
        plan = {
          tags = [ "myset" ];
          commands = [ "echo plan" ];
          needs = [
            {
              job = "validate";
              optional = true;
            }
          ];
        };
      };

      jobSets.myset = {
        tags = [ "myset" ];
        github-actions.reusableWorkflow = true;
      };
    };
    # The caller job for myset must list `validate` in its needs
    expected = {
      jobs = {
        validate = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "echo validate"; }
          ];
        };
        myset = {
          uses = "./.github/workflows/myset.yml";
          secrets = "inherit";
          needs = [ "validate" ];
        };
      };
    };
  };

  # Cross-job-set needs are stripped from jobs inside a reusable workflow:
  # job-b (in set-b) has a job-level need on job-a (in set-a). Since set-a is
  # also reusable, job-b's need on job-a must be stripped from the reusable
  # workflow file — ordering is guaranteed at the caller level.
  test-github-actions-reusable-workflow-strips-cross-set-needs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

          jobs = {
            job-a = {
              tags = [ "set-a" ];
              commands = [ "echo a" ];
            };
            job-b = {
              tags = [ "set-b" ];
              commands = [ "echo b" ];
              needs = [ { job = "job-a"; } ];
            };
          };

          jobSets = {
            set-a = {
              tags = [ "set-a" ];
              github-actions.reusableWorkflow = true;
            };
            set-b = {
              tags = [ "set-b" ];
              needs = [ { jobSet = "set-a"; } ];
              github-actions.reusableWorkflow = true;
            };
          };
        };
      in
      cfg.pipeline.github-actions.reusableWorkflowSettings.set-b;
    # job-b must have no `needs` (the cross-set need on job-a is stripped)
    expected = {
      on.workflow_call = { };
      jobs.job-b = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "echo b"; }
        ];
      };
    };
  };

  # Cross-job-set optional needs: the `if` condition referencing the external job
  # is also stripped from the reusable workflow.
  test-github-actions-reusable-workflow-strips-cross-set-optional-needs = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

          jobs = {
            job-a = {
              tags = [ "set-a" ];
              commands = [ "echo a" ];
            };
            job-b = {
              tags = [ "set-b" ];
              commands = [ "echo b" ];
              needs = [
                {
                  job = "job-a";
                  optional = true;
                }
              ];
            };
          };

          jobSets = {
            set-a = {
              tags = [ "set-a" ];
              github-actions.reusableWorkflow = true;
            };
            set-b = {
              tags = [ "set-b" ];
              needs = [ { jobSet = "set-a"; } ];
              github-actions.reusableWorkflow = true;
            };
          };
        };
      in
      cfg.pipeline.github-actions.reusableWorkflowSettings.set-b;
    # job-b must have no `needs` and no `if` (both stripped)
    expected = {
      on.workflow_call = { };
      jobs.job-b = {
        runs-on = "ubuntu-latest";
        steps = [
          { uses = "actions/checkout@v6"; }
          { run = "echo b"; }
        ];
      };
    };
  };

  # Mixed: inline job appears as-is, reusable job-set appears as workflow_call job
  test-github-actions-reusable-workflow-mixed = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        job-inline.tags = [ "inline-set" ];
        job-rw.tags = [ "rw-set" ];
      };

      jobSets = {
        inline-set.tags = [ "inline-set" ];
        rw-set = {
          tags = [ "rw-set" ];
          github-actions.reusableWorkflow = true;
        };
      };
    };
    expected = {
      jobs = {
        job-inline = {
          runs-on = "ubuntu-latest";
          steps = [ { uses = "actions/checkout@v6"; } ];
        };
        rw-set = {
          uses = "./.github/workflows/rw-set.yml";
          secrets = "inherit";
        };
      };
    };
  };

  # When reusableWorkflowFile is set, the caller job uses that path as `uses:`
  test-github-actions-reusable-workflow-redirect-uses = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs.deploy = {
        tags = [ "myset" ];
        commands = [ "tf-deploy svc dev" ];
      };

      jobSets.myset = {
        tags = [ "myset" ];
        github-actions = {
          reusableWorkflow = true;
          reusableWorkflowFile = "./.github/workflows/profile-terraform.yml";
          reusableWorkflowInputs = {
            service = "svc";
            deployment = "dev";
          };
        };
      };
    };
    expected = {
      jobs.myset = {
        uses = "./.github/workflows/profile-terraform.yml";
        secrets = "inherit";
        "with" = {
          service = "svc";
          deployment = "dev";
        };
      };
    };
  };

  # callerExtraNeeds adds extra entries to the caller job's needs
  test-github-actions-reusable-workflow-caller-extra-needs = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        changes.commands = [ "echo changes" ];
        deploy = {
          tags = [ "myset" ];
          commands = [ "tf-deploy svc dev" ];
        };
      };

      jobSets.myset = {
        tags = [ "myset" ];
        github-actions = {
          reusableWorkflow = true;
          reusableWorkflowFile = "./.github/workflows/profile-terraform.yml";
          reusableWorkflowInputs = {
            service = "svc";
            deployment = "dev";
          };
          callerExtraNeeds = [ "changes" ];
        };
      };
    };
    expected = {
      jobs = {
        changes = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "echo changes"; }
          ];
        };
        myset = {
          uses = "./.github/workflows/profile-terraform.yml";
          secrets = "inherit";
          "with" = {
            service = "svc";
            deployment = "dev";
          };
          needs = [ "changes" ];
        };
      };
    };
  };

  # A reusable job-set with no enabled jobs must not appear in reusableWorkflowSettings
  test-github-actions-reusable-workflow-empty-jobset-no-yml = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

          jobSets.empty-set = {
            tags = [ "empty-set" ];
            github-actions.reusableWorkflow = true;
          };
        };
      in
      cfg.pipeline.github-actions.reusableWorkflowSettings;
    # No entry for "empty-set" — it has no jobs, so no workflow file should be generated
    expected = { };
  };

  # A reusable job-set with no enabled jobs must not appear as a caller job in ci.yaml
  test-github-actions-reusable-workflow-empty-jobset-no-caller = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobSets.empty-set = {
        tags = [ "empty-set" ];
        github-actions.reusableWorkflow = true;
      };
    };
    # No caller job for "empty-set" — nothing to call
    expected = {
      jobs = { };
    };
  };

  # When reusableWorkflowFile is set, no .yml is generated for that job-set
  test-github-actions-reusable-workflow-redirect-no-yml = {
    expr =
      let
        cfg = test-lib.evalConfig {
          pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

          jobs.deploy = {
            tags = [ "myset" ];
            commands = [ "tf-deploy svc dev" ];
          };

          jobSets.myset = {
            tags = [ "myset" ];
            github-actions = {
              reusableWorkflow = true;
              reusableWorkflowFile = "./.github/workflows/profile-terraform.yml";
              reusableWorkflowInputs = {
                service = "svc";
                deployment = "dev";
              };
            };
          };
        };
      in
      cfg.pipeline.github-actions.reusableWorkflowSettings;
    # No entry for "myset" — it is a redirect, not a generated workflow
    expected = { };
  };

  # transformJobName is applied to job-set names used as caller job IDs:
  # a reusable job-set named "set:dev" must appear as "set_dev" in ci.yaml
  test-github-actions-reusable-workflow-transform-jobset-name = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions = {
        defaultRunsOn = "ubuntu-latest";
        transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      };

      jobs."job:a".tags = [ "set:dev" ];

      jobSets."set:dev" = {
        tags = [ "set:dev" ];
        github-actions.reusableWorkflow = true;
      };
    };
    expected = {
      jobs.set_dev = {
        uses = "./.github/workflows/set:dev.yml";
        secrets = "inherit";
      };
    };
  };

  # transformJobName is applied to cross-set needs references:
  # when set:b depends on set:a both names must be transformed in the needs list
  test-github-actions-reusable-workflow-transform-cross-set-needs = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions = {
        defaultRunsOn = "ubuntu-latest";
        transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      };

      jobs = {
        "job:a".tags = [ "set:a" ];
        "job:b".tags = [ "set:b" ];
      };

      jobSets = {
        "set:a" = {
          tags = [ "set:a" ];
          github-actions.reusableWorkflow = true;
        };
        "set:b" = {
          tags = [ "set:b" ];
          needs = [ { jobSet = "set:a"; } ];
          github-actions.reusableWorkflow = true;
        };
      };
    };
    expected = {
      jobs = {
        set_a = {
          uses = "./.github/workflows/set:a.yml";
          secrets = "inherit";
        };
        set_b = {
          uses = "./.github/workflows/set:b.yml";
          secrets = "inherit";
          needs = [ "set_a" ];
        };
      };
    };
  };

  # callerIf adds an `if:` condition to the caller job
  test-github-actions-reusable-workflow-caller-if = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs = {
        changes.commands = [ "echo changes" ];
        deploy = {
          tags = [ "myset" ];
          commands = [ "tf-deploy svc dev" ];
        };
      };

      jobSets.myset = {
        tags = [ "myset" ];
        github-actions = {
          reusableWorkflow = true;
          reusableWorkflowFile = "./.github/workflows/profile-terraform.yml";
          reusableWorkflowInputs = {
            service = "svc";
            deployment = "dev";
          };
          callerExtraNeeds = [ "changes" ];
          callerIf = "\${{ fromJSON(needs.changes.outputs.changes)['svc:dev:plan'] == true }}";
        };
      };
    };
    expected = {
      jobs = {
        changes = {
          runs-on = "ubuntu-latest";
          steps = [
            { uses = "actions/checkout@v6"; }
            { run = "echo changes"; }
          ];
        };
        myset = {
          uses = "./.github/workflows/profile-terraform.yml";
          secrets = "inherit";
          needs = [ "changes" ];
          "with" = {
            service = "svc";
            deployment = "dev";
          };
          "if" = "\${{ fromJSON(needs.changes.outputs.changes)['svc:dev:plan'] == true }}";
        };
      };
    };
  };

  # External reusable workflow job-sets (reusableWorkflowFile != null) must contribute
  # their jobs' changes.paths entries to the outer changes job in ci.yaml.
  # Without this, callerIf conditions referencing those keys are always false.
  test-github-actions-reusable-workflow-redirect-changes-in-outer-changes-job = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions.defaultRunsOn = "ubuntu-latest";

      jobs.deploy = {
        tags = [ "myset" ];
        commands = [ "tf-deploy svc dev" ];
        branches.default.changes.paths = [
          "services/svc/config/dev/*"
          "services/svc/module/**/*"
        ];
      };

      jobSets.myset = {
        tags = [ "myset" ];
        github-actions = {
          reusableWorkflow = true;
          reusableWorkflowFile = "./.github/workflows/profile-terraform.yml";
          reusableWorkflowInputs = {
            service = "svc";
            deployment = "dev";
          };
        };
      };
    };
    # The outer changes job must exist and include deploy's paths
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
                DIFF_PATHS = "deploy:services/svc/config/dev/*\\|services/svc/module/**/*";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        myset = {
          uses = "./.github/workflows/profile-terraform.yml";
          secrets = "inherit";
          "with" = {
            service = "svc";
            deployment = "dev";
          };
        };
      };
    };
  };

  # transformJobName is applied to job-set names used as caller job IDs
  # when reusableWorkflowFile redirects to an external workflow file
  test-github-actions-reusable-workflow-transform-redirect-jobset-name = {
    expr = test-lib.eval-github-actions {
      pipeline.github-actions = {
        defaultRunsOn = "ubuntu-latest";
        transformJobName = builtins.replaceStrings [ ":" ] [ "_" ];
      };

      jobs."deploy:dev" = {
        tags = [ "set:dev" ];
        commands = [ "tf-deploy svc dev" ];
      };

      jobSets."set:dev" = {
        tags = [ "set:dev" ];
        github-actions = {
          reusableWorkflow = true;
          reusableWorkflowFile = "./.github/workflows/profile-terraform.yml";
          reusableWorkflowInputs = {
            service = "svc";
            deployment = "dev";
          };
        };
      };
    };
    expected = {
      jobs.set_dev = {
        uses = "./.github/workflows/profile-terraform.yml";
        secrets = "inherit";
        "with" = {
          service = "svc";
          deployment = "dev";
        };
      };
    };
  };
}
