{ test-lib, ... }:

let
  forceRunAllInput = {
    type = "boolean";
    default = false;
    description = "Skip change detection and run all jobs";
  };
in
{
  test-github-actions-job-pipeline-call-basic = {
    expr = test-lib.eval-github-actions {
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs = {
          environment = "prod";
        };
      };
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/my-pipeline.yml";
        secrets = "inherit";
        "with".environment = "prod";
      };
    };
  };

  test-github-actions-job-pipeline-call-no-steps-or-runs-on = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy.pipelineCall.pipeline = "my-pipeline";
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/my-pipeline.yml";
        secrets = "inherit";
        "with" = { };
      };
    };
  };

  # The pipeline-call job itself does NOT appear as a regular jobs entry.
  test-github-actions-job-pipeline-call-job-suppressed = {
    expr =
      (test-lib.eval-github-actions {
        jobs.deploy.pipelineCall.pipeline = "my-pipeline";
      }).jobs.deploy ? "steps";
    expected = false;
  };

  test-github-actions-job-pipeline-call-with-changes = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        branches.default.changes.paths = [ "src/**" ];
        pipelineCall.pipeline = "my-pipeline";
      };
    };
    expected = {
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v6";
              "with"."fetch-depth" = 0;
            }
            {
              id = "diff";
              shell = "bash";
              env = {
                DIFF_PATHS = "deploy:src/**";
                GITHUB_EVENT_BEFORE = "\${{ github.event.before }}";
                GITHUB_EVENT_AFTER = "\${{ github.event.after }}";
                FORCE_RUN_ALL = "\${{ inputs.force_run_all }}";
              };
              run = builtins.readFile ../../../packages/gha-path-changes/main.bash;
            }
          ];
        };
        deploy = {
          uses = "./.github/workflows/my-pipeline.yml";
          secrets = "inherit";
          needs = [ "changes" ];
          "if" = ''''${{ fromJSON(needs.changes.outputs.changes)['deploy'] == true }}'';
          "with" = {
            changes = "\${{ needs.changes.outputs.changes }}";
            changes_key = "deploy";
          };
        };
      };
    };
  };

  test-github-actions-job-pipeline-call-pass-secrets-false = {
    expr = test-lib.eval-github-actions {
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        github-actions.passSecrets = false;
      };
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/my-pipeline.yml";
        "with" = { };
      };
    };
  };

  test-github-actions-job-pipeline-call-extra-inputs-merged-into-with = {
    expr = test-lib.eval-github-actions {
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        github-actions.extraInputs.ref = "main";
      };
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/my-pipeline.yml";
        secrets = "inherit";
        "with" = {
          environment = "prod";
          ref = "main";
        };
      };
    };
  };

  # GitLab-specific extraInputs must NOT appear in the GHA with block.
  test-github-actions-job-pipeline-call-gitlab-extra-inputs-not-in-gha = {
    expr = test-lib.eval-github-actions {
      jobs.deploy.pipelineCall = {
        pipeline = "my-pipeline";
        inputs.environment = "prod";
        gitlab-ci.extraInputs.plan_needs = "tf-plan";
      };
    };
    expected = {
      jobs.deploy = {
        uses = "./.github/workflows/my-pipeline.yml";
        secrets = "inherit";
        "with".environment = "prod";
      };
    };
  };

  # A pipeline with github-actions.changes.enable = true automatically declares
  # changes and changes_key as workflow_call inputs, so GitHub Actions accepts
  # the inputs injected by a parent job that has change detection configured.
  test-github-actions-pipeline-changes-inputs-auto-injected = {
    expr = test-lib.eval-github-actions {
      github-actions.changes.enable = true;
    };
    expected = {
      env = {
        CHANGES = "\${{ inputs.changes }}";
        CHANGES_KEY = "\${{ inputs.changes_key }}";
      };
      jobs = { };
      on.workflow_call.inputs = {
        changes = {
          type = "string";
          description = "Change detection JSON passed from the calling workflow.";
        };
        changes_key = {
          type = "string";
          description = "Key identifying this job in the change detection map.";
        };
      };
    };
  };
}
