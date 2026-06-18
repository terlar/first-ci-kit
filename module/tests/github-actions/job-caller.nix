{ test-lib, ... }:

let
  forceRunAllInput = {
    type = "boolean";
    default = false;
    description = "Skip change detection and run all jobs";
  };
in
{
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
      on.pull_request.branches = [ "main" ];
      on.workflow_dispatch.inputs.force_run_all = forceRunAllInput;
      jobs = {
        changes = {
          outputs.changes = "\${{ steps.diff.outputs.changes }}";
          runs-on = "ubuntu-latest";
          steps = [
            {
              uses = "actions/checkout@v7";
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
          uses = "./.github/workflows/profile-deploy.yml";
          needs = [ "changes" ];
          "if" =
            ''''${{ github.event_name == 'pull_request' && fromJSON(needs.changes.outputs.changes)['deploy'] == true }}'';
          "with".service = "my-service";
        };
      };
    };
  };
}
