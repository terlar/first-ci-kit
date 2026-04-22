{ test-lib, ... }:

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

  test-github-actions-job-pipeline-call-with-changes = {
    expr = test-lib.eval-github-actions {
      github-actions.defaultRunsOn = "ubuntu-latest";
      jobs.deploy = {
        branches.default.changes.paths = [ "src/**" ];
        pipelineCall.pipeline = "my-pipeline";
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
}
