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
}
